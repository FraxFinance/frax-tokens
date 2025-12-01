pragma solidity ^0.8.0;

import { ERC20PermitPermissionedOptiMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedOptiMintable.sol";
import { SignatureChecker } from "@openzeppelin/contracts-5.2.0/utils/cryptography/SignatureChecker.sol";

contract FrxUSD is ERC20PermitPermissionedOptiMintable {
    /// @dev keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 private constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    /// @dev keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 private constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
        0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    /// @dev keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
    bytes32 private constant CANCEL_AUTHORIZATION_TYPEHASH =
        0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

    /// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 private constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Mapping indicating which addresses are frozen
    mapping(address => bool) public isFrozen;

    /// @notice Whether or not the contract is paused
    bool public isPaused;

    /// @notice Mapping indiciating which addresses can freeze accounts
    mapping(address => bool) public isFreezer;

    /// @notice Mapping of authorizer to nonce to authorization state used for EIP-3009
    mapping(address authorizer => mapping(bytes32 nonce => bool used)) public authorizationState;

    /// @notice Upgrade version of the contract
    /// @dev Does not impact EIP712 version, which is automatically set to "1" in constructor
    function version() public pure override returns (string memory) {
        return "3.0.0";
    }

    /// @param _creator_address The contract creator
    /// @param _timelock_address The timelock
    /// @param _bridge Address of the L2 standard bridge
    /// @param _remoteToken Address of the corresponding L1 token
    constructor(
        address _creator_address,
        address _timelock_address,
        address _bridge,
        address _remoteToken
    )
        ERC20PermitPermissionedOptiMintable(
            _creator_address,
            _timelock_address,
            _bridge,
            _remoteToken,
            "Frax USD",
            "frxUSD"
        )
    {}

    function addFreezer(address _freezer) external onlyOwner {
        if (isFreezer[_freezer]) revert AlreadyFreezer();
        isFreezer[_freezer] = true;
        emit AddFreezer(_freezer);
    }

    function removeFreezer(address _freezer) external onlyOwner {
        if (!isFreezer[_freezer]) revert NotFreezer();
        isFreezer[_freezer] = false;
        emit RemoveFreezer(_freezer);
    }

    /// @notice External admin gated function to unfreeze a set of accounts
    /// @param _owners Array of accounts to be unfrozen
    function thawMany(address[] memory _owners) external onlyOwner {
        uint256 len = _owners.length;
        for (uint256 i; i < len; ++i) {
            _thaw(_owners[i]);
        }
    }

    /// @notice External admin gated function to unfreeze an account
    /// @param _owner The account to be unfrozen
    function thaw(address _owner) external onlyOwner {
        _thaw(_owner);
    }

    /// @notice External admin gated function to batch freeze a set of accounts
    /// @param _owners Array of accounts to be frozen
    function freezeMany(address[] memory _owners) external {
        if (!isFreezer[msg.sender] && msg.sender != owner) revert NotFreezer();
        uint256 len = _owners.length;
        for (uint256 i; i < len; ++i) {
            _freeze(_owners[i]);
        }
    }

    /// @notice External admin gated function to freeze a given account
    /// @param _owner The account to be
    function freeze(address _owner) external {
        if (!isFreezer[msg.sender] && msg.sender != owner) revert NotFreezer();
        _freeze(_owner);
    }

    /// @notice External admin gated function to batch burn balance from a set of accounts
    /// @param _owners Array of accounts whose balances will be burned
    /// @param _amounts Array of amounts corresponding to the balances to be burned
    /// @dev if `_amount` == 0, entire balance will be burned
    function burnMany(address[] memory _owners, uint256[] memory _amounts) external onlyOwner {
        uint256 lenOwner = _owners.length;
        if (_owners.length != _amounts.length) revert ArrayMisMatch();
        for (uint256 i; i < lenOwner; ++i) {
            if (_amounts[i] == 0) _amounts[i] = balanceOf(_owners[i]);
            _burn(_owners[i], _amounts[i]);
        }
    }

    /// @notice External admin gated function to burn balance from a given account
    /// @param _owner  The account whose balance will be burned
    /// @param _amount The amount of balance to burn
    /// @dev if `_amount` == 0, entire balance will be burned
    function burnFrxUsd(address _owner, uint256 _amount) external onlyOwner {
        if (_amount == 0) _amount = balanceOf(_owner);
        _burn(_owner, _amount);
    }

    /// @notice External admin gated pause function
    function pause() external onlyOwner {
        isPaused = true;
        emit Paused();
    }

    /// @notice External admin gated unpause function
    function unpause() external onlyOwner {
        isPaused = false;
        emit Unpaused();
    }

    /* ========== PERMIT ========== */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        bytes memory signature
    ) external virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        _requireIsValidSignatureNow({
            signer: owner,
            structHash: keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)),
            signature: signature
        });

        _approve(owner, spender, value);
    }

    /* ========== EIP-3009 ========== */

    /// @notice The ```transferWithAuthorization``` function executes a transfer with a signed authorization according to Eip3009
    /// @dev EOA wallet signatures should be packed in the order of r, s, v
    /// @dev added in v1.1.0
    /// @param from Payer's address (Authorizer)
    /// @param to Payee's address
    /// @param value Amount to be transferred
    /// @param validAfter The block.timestamp after which the authorization is valid
    /// @param validBefore The block.timestamp before which the authorization is valid
    /// @param nonce Unique nonce
    /// @param v ECDSA signature parameter v
    /// @param r ECDSA signature parameters r
    /// @param s ECDSA signature parameters s
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Packs signature pieces into bytes
        transferWithAuthorization({
            from: from,
            to: to,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            signature: abi.encodePacked(r, s, v)
        });
    }

    /// @notice The ```transferWithAuthorization``` function executes a transfer with a signed authorization
    /// @dev EOA wallet signatures should be packed in the order of r, s, v
    /// @param from Payer's address (Authorizer)
    /// @param to Payee's address
    /// @param value Amount to be transferred
    /// @param validAfter The time after which this is valid (unix time)
    /// @param validBefore The time before which this is valid (unix time)
    /// @param nonce Unique nonce
    /// @param signature Signature byte array produced by an EOA wallet or a contract wallet
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes memory signature
    ) public {
        // Checks: authorization validity
        if (block.timestamp <= validAfter) revert InvalidAuthorization();
        if (block.timestamp >= validBefore) revert ExpiredAuthorization();
        _requireUnusedAuthorization({ authorizer: from, nonce: nonce });

        // Checks: valid signature
        _requireIsValidSignatureNow({
            signer: from,
            structHash: keccak256(
                abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce)
            ),
            signature: signature
        });

        // Effects: mark authorization as used and transfer
        _markAuthorizationAsUsed({ authorizer: from, nonce: nonce });
        _transfer({ from: from, to: to, value: value });
    }

    /// @notice The ```receiveWithAuthorization``` function receives a transfer with a signed authorization from the payer
    /// @dev This has an additional check to ensure that the payee's address matches the caller of this function to prevent front-running attacks
    /// @dev EOA wallet signatures should be packed in the order of r, s, v
    /// @param from Payer's address (Authorizer)
    /// @param to Payee's address
    /// @param value Amount to be transferred
    /// @param validAfter The block.timestamp after which the authorization is valid
    /// @param validBefore The block.timestamp before which the authorization is valid
    /// @param nonce Unique nonce
    /// @param v ECDSA signature parameter v
    /// @param r ECDSA signature parameters r
    /// @param s ECDSA signature parameters s
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Packs signature pieces into bytes
        receiveWithAuthorization({
            from: from,
            to: to,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            signature: abi.encodePacked(r, s, v)
        });
    }

    /// @notice The ```receiveWithAuthorization``` function receives a transfer with a signed authorization from the payer
    /// @dev This has an additional check to ensure that the payee's address matches the caller of this function to prevent front-running attacks
    /// @dev EOA wallet signatures should be packed in the order of r, s, v
    /// @param from Payer's address (Authorizer)
    /// @param to Payee's address
    /// @param value Amount to be transferred
    /// @param validAfter The block.timestamp after which the authorization is valid
    /// @param validBefore The block.timestamp before which the authorization is valid
    /// @param nonce Unique nonce
    /// @param signature Signature byte array produced by an EOA wallet or a contract wallet
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        bytes memory signature
    ) public {
        // Checks: authorization validity
        if (to != msg.sender) revert InvalidPayee({ caller: msg.sender, payee: to });
        if (block.timestamp <= validAfter) revert InvalidAuthorization();
        if (block.timestamp >= validBefore) revert ExpiredAuthorization();
        _requireUnusedAuthorization({ authorizer: from, nonce: nonce });

        // Checks: valid signature
        _requireIsValidSignatureNow({
            signer: from,
            structHash: keccak256(
                abi.encode(RECEIVE_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce)
            ),
            signature: signature
        });

        // Effects: mark authorization as used and transfer
        _markAuthorizationAsUsed({ authorizer: from, nonce: nonce });
        _transfer({ from: from, to: to, value: value });
    }

    /// @notice The ```cancelAuthorization``` function cancels an authorization nonce
    /// @dev EOA wallet signatures should be packed in the order of r, s, v
    /// @param authorizer   Authorizer's address
    /// @param nonce        Nonce of the authorization
    /// @param v            ECDSA signature v value
    /// @param r            ECDSA signature r value
    /// @param s            ECDSA signature s value
    function cancelAuthorization(address authorizer, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external {
        cancelAuthorization({ authorizer: authorizer, nonce: nonce, signature: abi.encodePacked(r, s, v) });
    }

    /// @notice The ```cancelAuthorization``` function cancels an authorization nonce
    /// @dev EOA wallet signatures should be packed in the order of r, s, v
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    /// @param signature     Signature byte array produced by an EOA wallet or a contract wallet
    function cancelAuthorization(address authorizer, bytes32 nonce, bytes memory signature) public {
        _requireUnusedAuthorization({ authorizer: authorizer, nonce: nonce });
        _requireIsValidSignatureNow({
            signer: authorizer,
            structHash: keccak256(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, authorizer, nonce)),
            signature: signature
        });

        authorizationState[authorizer][nonce] = true;
        emit AuthorizationCanceled({ authorizer: authorizer, nonce: nonce });
    }

    /* ========== INTERNAL METHODS ========== */
    function _requireIsValidSignatureNow(address signer, bytes32 structHash, bytes memory signature) internal view {
        if (
            !SignatureChecker.isValidSignatureNow({
                signer: signer,
                hash: _hashTypedDataV4({ structHash: structHash }),
                signature: signature
            }) || signer == address(0)
        ) revert InvalidSignature();
    }

    /// @notice The ```_requireUnusedAuthorization``` checks that an authorization nonce is unused
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    function _requireUnusedAuthorization(address authorizer, bytes32 nonce) private view {
        if (authorizationState[authorizer][nonce]) revert UsedOrCanceledAuthorization();
    }

    /// @notice The ```_markAuthorizationAsUsed``` function marks an authorization nonce as used
    /// @param authorizer    Authorizer's address
    /// @param nonce         Nonce of the authorization
    function _markAuthorizationAsUsed(address authorizer, bytes32 nonce) private {
        authorizationState[authorizer][nonce] = true;
        emit AuthorizationUsed({ authorizer: authorizer, nonce: nonce });
    }

    /* ========== Internals For Admin Gated ========== */

    /// @notice Internal helper function to freeze an account
    /// @param _owner The account to 'frozen'
    function _freeze(address _owner) internal {
        isFrozen[_owner] = true;
        emit AccountFrozen(_owner);
    }

    /// @notice Internal helper function to unfreeze an account
    /// @param _owner The account to unfreeze
    function _thaw(address _owner) internal {
        isFrozen[_owner] = false;
        emit AccountThawed(_owner);
    }

    /* ========== Overrides ========== */

    /// @notice override for base internal `_update(address,address,uint256)`
    ///         implements `paused` and `frozen` transfer logic
    /// @param from  The address from which balance is originating
    /// @param to    The address whose balance will be incremented
    /// @param value The amount to increment/decrement the balances of
    /// @dev Owner can bypass pause and freeze checks
    function _update(address from, address to, uint256 value) internal override {
        if (msg.sender != owner) {
            if (isPaused) revert IsPaused();
            if (isFrozen[to] || isFrozen[from] || isFrozen[msg.sender]) revert IsFrozen();
        }
        super._update(from, to, value);
    }

    /* ========== EVENTS ========== */
    /// @notice ```AuthorizationUsed``` event is emitted when an authorization is used
    /// @param authorizer Authorizer's address
    /// @param nonce Nonce of the authorization
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    /// @notice ```AuthorizationCanceled``` event is emitted when an authorization is canceled
    /// @param authorizer Authorizer's address
    /// @param nonce Nonce of the authorization
    event AuthorizationCanceled(address indexed authorizer, bytes32 indexed nonce);

    /// @notice Event Emitted when the contract is paused
    event Paused();

    /// @notice Event Emitted when the contract is unpaused
    event Unpaused();

    /// @notice Event Emitted when an address is frozen
    /// @param account The account being frozen
    event AccountFrozen(address account);

    /// @notice Event Emitted when an address is unfrozen
    /// @param account The account being thawed
    event AccountThawed(address account);

    /// @notice Event Emitted when an address is added as a freezer
    /// @param account The account being added as a freezer
    event AddFreezer(address account);

    /// @notice Event Emitted when an address is removed as a freezer
    /// @param account The account being removed as a freezer
    event RemoveFreezer(address account);

    /* ========== ERRORS ========== */
    error ArrayMisMatch();
    error IsPaused();
    error IsFrozen();
    error NotFreezer();
    error AlreadyFreezer();

    /// @notice Error thrown when a signature is invalid
    error InvalidSignature();

    /// @notice The ```InvalidPayee``` error is emitted when the payee does not match sender in receiveWithAuthorization
    /// @param caller The caller of the function
    /// @param payee The expected payee in the function
    error InvalidPayee(address caller, address payee);

    /// @notice The ```InvalidAuthorization``` error is emitted when the authorization is invalid because its too early
    error InvalidAuthorization();

    /// @notice The ```ExpiredAuthorization``` error is emitted when the authorization is expired
    error ExpiredAuthorization();

    /// @notice The ```UsedOrCanceledAuthorization``` error is emitted when the authorization nonce is already used or canceled
    error UsedOrCanceledAuthorization();
}
