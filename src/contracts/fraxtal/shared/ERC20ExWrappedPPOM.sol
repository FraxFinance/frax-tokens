// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================== ERC20ExWrappedPPOM ========================
// ====================================================================
// Converts a WETH-like into an ERC20PermitPermissionedOptiMintable.
// WETH and ERC20 state vars were in different orders, so needed to correctly account for that to preserve data
// Combines OZ's ERC20Permit and EIP721 into one contract. This was needed because of upgrade issues
// EIP712's _cached & _hashed immutables needed to be converted to private variables so _buildDomainSeparator works,
// as the token name & symbol changed to "Frax Ether" and "frxETH" respectively

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
//
//
import { ECDSA } from "@openzeppelin/contracts-5.2.0/utils/cryptography/ECDSA.sol";
import { ERC20Burnable } from "@openzeppelin/contracts-5.2.0/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit, ERC20 } from "@openzeppelin/contracts-5.2.0/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20ReorderedState } from "src/contracts/fraxtal/shared/ERC20ReorderedState.sol";
import { IERC165 } from "@openzeppelin/contracts-5.2.0/utils/introspection/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts-5.2.0/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts-5.2.0/token/ERC20/extensions/IERC20Permit.sol";
import { IERC5267 } from "@openzeppelin/contracts-5.2.0/interfaces/IERC5267.sol";
import { ILegacyMintableERC20 } from "src/contracts/fraxtal/shared/interfaces/ILegacyMintableERC20.sol";
import { IOptimismMintableERC20 } from "src/contracts/fraxtal/shared/interfaces/IOptimismMintableERC20.sol";
import { ISemver } from "src/contracts/fraxtal/shared/interfaces/ISemver.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable-5.2.0/proxy/utils/Initializable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts-5.2.0/utils/cryptography/MessageHashUtils.sol";
import { Nonces } from "@openzeppelin/contracts-5.2.0/utils/Nonces.sol";
import { OwnedV2 } from "src/contracts/fraxtal/shared/OwnedV2.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts-5.2.0/utils/ShortStrings.sol";
import { EIP712StoragePad } from "src/contracts/fraxtal/shared/EIP712StoragePad.sol";

/// @title New contract for frxETH. Formerly wfrxETH.
/**
 * @notice Combines Openzeppelin's ERC20Permit and ERC20Burnable with Synthetix's Owned and Optimism's OptimismMintableERC20.
 *     Also includes a list of authorized minters
 */
/// @dev ERC20PermitPermissionedOptiMintable adheres to EIP-712/EIP-2612 and can use permits
contract ERC20ExWrappedPPOM is
    Initializable,
    IERC20,
    IERC20Permit,
    EIP712StoragePad,
    Nonces,
    ERC20ReorderedState,
    OwnedV2,
    IOptimismMintableERC20,
    ILegacyMintableERC20,
    IERC5267,
    ISemver
{
    using ShortStrings for *;

    // EIP721
    // =======================================
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    string private _nameFallback;
    string private _versionFallback;

    bytes32 private _cachedDomainSeparator;
    uint256 private _cachedChainId;
    address private _cachedThis;

    bytes32 private _hashedName;
    bytes32 private _hashedVersion;

    ShortString private _SStrName;
    ShortString private _SStrVersion;

    // ERC20PermitPermissionedOptiMintable
    // =======================================
    /// @notice The timelock address
    address public timelock_address;

    /// @notice Array of the non-bridge minters
    address[] public minters_array;

    /// @notice Mapping of the non-bridge minters
    /// @dev Mapping is used for faster verification
    mapping(address => bool) public minters;

    /// @notice Address of the L2 StandardBridge on this network.
    address public BRIDGE;

    /// @notice Address of the corresponding version of this token on the remote chain.
    address public REMOTE_TOKEN;

    // ISemver
    // =======================================
    /// @custom:semver 1.1.0
    string public version = "1.1.0";

    /* ========== CONSTRUCTOR ========== */

    constructor() ERC20ReorderedState("Dummy Token", "DUMMY") OwnedV2(address(1)) {
        _disableInitializers();
    }

    /* ========== MODIFIERS ========== */

    /// @notice A modifier that only allows the contract owner or the timelock to call
    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    /// @notice A modifier that only allows a non-bridge minter to call
    modifier onlyMinters() {
        require(minters[msg.sender] == true, "Only minters");
        _;
    }

    /// @notice A modifier that only allows the bridge to call
    modifier onlyBridge() {
        require(msg.sender == BRIDGE, "OptimismMintableERC20: only bridge can mint and burn");
        _;
    }

    /* ========== LEGACY VIEWS ========== */

    /// @custom:legacy
    /// @notice Legacy getter for the remote token. Use REMOTE_TOKEN going forward.
    /// @return address The L1 remote token address
    function l1Token() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for the bridge. Use BRIDGE going forward.
    /// @return address The bridge address
    function l2Bridge() public view returns (address) {
        return BRIDGE;
    }

    /// @custom:legacy
    /// @notice Legacy getter for REMOTE_TOKEN
    /// @return address The L1 remote token address
    function remoteToken() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for BRIDGE
    /// @return address The bridge address
    function bridge() public view returns (address) {
        return BRIDGE;
    }

    /// @notice ERC165 interface check function.
    /// @param _interfaceId Interface ID to check.
    /// @return Whether or not the interface is supported by this contract.
    function supportsInterface(bytes4 _interfaceId) external pure virtual returns (bool) {
        return _interfaceId == type(IERC165).interfaceId;
    }

    /* ========== RESTRICTED FUNCTIONS [BRIDGE] ========== */

    /// @notice Allows the StandardBridge on this network to mint tokens.
    /// @dev Deprecated in v1.1.0
    function mint(address, uint256) external virtual override(IOptimismMintableERC20, ILegacyMintableERC20) {
        revert Deprecated();
    }

    /// @notice Allows the StandardBridge on this network to burn tokens. No approval needed
    /// @dev Deprecated in v1.1.0
    function burn(address, uint256) external virtual override(IOptimismMintableERC20, ILegacyMintableERC20) {
        revert Deprecated();
    }

    /* ========== RESTRICTED FUNCTIONS [NON-BRIDGE MINTERS] ========== */

    /// @notice Sames as burnFrom. Left here for backwards-compatibility. Used by non-bridge minters to burn tokens. Must have approval first.
    /// @param b_address Address of the account to burn from
    /// @param b_amount Amount of tokens to burn
    function minter_burn_from(address b_address, uint256 b_amount) public onlyMinters {
        burnFrom(b_address, b_amount);
        emit TokenMinterBurned(b_address, msg.sender, b_amount);
    }

    /// @notice Used by non-bridge minters to mint new tokens
    /// @param m_address Address of the account to mint to
    /// @param m_amount Amount of tokens to mint
    function minter_mint(address m_address, uint256 m_amount) public onlyMinters {
        _mint(m_address, m_amount);
        emit TokenMinterMinted(msg.sender, m_address, m_amount);
    }

    /// @notice Adds a non-bridge minter
    /// @param minter_address Address of minter to add
    function addMinter(address minter_address) public onlyByOwnGov {
        require(minter_address != address(0), "Zero address detected");

        require(minters[minter_address] == false, "Address already exists");
        minters[minter_address] = true;
        minters_array.push(minter_address);

        emit MinterAdded(minter_address);
    }

    /// @notice Removes a non-bridge minter
    /// @param minter_address Address of minter to remove
    function removeMinter(address minter_address) public onlyByOwnGov {
        require(minter_address != address(0), "Zero address detected");
        require(minters[minter_address] == true, "Address non-existent");

        // Delete from the mapping
        delete minters[minter_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < minters_array.length; i++) {
            if (minters_array[i] == minter_address) {
                minters_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit MinterRemoved(minter_address);
    }

    // ERC20Burnable Functions
    // =============================================
    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, deducting from
     * the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     */
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }

    /* ========== EIP712 FUNCTIONS ========== */

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _SStrName.toStringWithFallback(_nameFallback),
            _SStrVersion.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /* ========== ERC20Permit FUNCTIONS ========== */

    /**
     * @dev Permit deadline has expired.
     */
    error ERC2612ExpiredSignature(uint256 deadline);

    /**
     * @dev Mismatched signature.
     */
    error ERC2612InvalidSigner(address signer, address owner);

    /**
     * @inheritdoc IERC20Permit
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        _approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    /**
     * @inheritdoc IERC20Permit
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    /* ========== RESTRICTED FUNCTIONS [ADMIN-RELATED] ========== */

    /// @notice Adjust the totalSupply
    function adjustTotalSupply(int256 _newTotalSupplyDiff) public onlyByOwnGov {
        if (_newTotalSupplyDiff < 0) {
            _totalSupply -= uint256(-_newTotalSupplyDiff);
        } else {
            _totalSupply += uint256(_newTotalSupplyDiff);
        }
    }

    /// @notice Sets the timelock address
    /// @param _timelock_address Address of the timelock
    function setTimelock(address _timelock_address) public onlyByOwnGov {
        require(_timelock_address != address(0), "Zero address detected");
        timelock_address = _timelock_address;
        emit TimelockChanged(_timelock_address);
    }

    /* ========== EVENTS ========== */

    /// @notice Emitted when a non-bridge minter is added
    /// @param minter_address Address of the new minter
    event MinterAdded(address minter_address);

    /// @notice Emitted when a non-bridge minter is removed
    /// @param minter_address Address of the removed minter
    event MinterRemoved(address minter_address);

    /// @notice Emitted when the timelock address changes
    /// @param timelock_address Address of the new timelock
    event TimelockChanged(address timelock_address);

    /// @notice Emitted when a non-bridge minter burns tokens
    /// @param from The account whose tokens are burned
    /// @param to The minter doing the burning
    /// @param amount Amount of tokens burned
    event TokenMinterBurned(address indexed from, address indexed to, uint256 amount);

    /// @notice Emitted when a non-bridge minter mints tokens
    /// @param from The minter doing the minting
    /// @param to The account that gets the newly minted tokens
    /// @param amount Amount of tokens minted
    event TokenMinterMinted(address indexed from, address indexed to, uint256 amount);

    /// @notice Error for deprecated functions
    error Deprecated();
}
