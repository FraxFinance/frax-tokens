pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts-5.2.0/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts-5.2.0/token/ERC20/extensions/IERC20Permit.sol";
import { ILegacyMintableERC20 } from "src/contracts/fraxtal/shared/interfaces/ILegacyMintableERC20.sol";
import { IOptimismMintableERC20 } from "src/contracts/fraxtal/shared/interfaces/IOptimismMintableERC20.sol";
import { ISemver } from "src/contracts/fraxtal/shared/interfaces/ISemver.sol";

interface IERC20PermitPermissionedOptiMintable is
    IERC20,
    IERC20Permit,
    ILegacyMintableERC20,
    IOptimismMintableERC20,
    ISemver
{
    /// @dev state variables
    function timelock_address() external view returns (address);
    function BRIDGE() external view returns (address);
    function REMOTE_TOKEN() external view returns (address);
    function minters_array(uint256) external view returns (address);
    function minters(address) external view returns (bool);

    /// @dev OwnedV2
    function owner() external view returns (address);
    function nominatedOwner() external view returns (address);
    function nominateNewOwner(address _owner) external;
    function acceptOwnership() external;

    error OwnerCannotBeZero();
    error InvalidOwnershipAcceptance();
    error OnlyOwner();

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);

    /// @dev ERC20Burnable
    function burn(uint256 value) external;
    function burnFrom(address account, uint256 value) external;

    /// @dev erc165 interface check function
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// @dev restricted functions (bridge)
    function mint(address _to, uint256 _amount) external override(ILegacyMintableERC20, IOptimismMintableERC20);
    function burn(address _from, uint256 _amount) external override(ILegacyMintableERC20, IOptimismMintableERC20);

    /// @dev restricted functions (non-bridge minters)
    function minter_burn_from(address b_address, uint256 b_amount) external;
    function minter_mint(address m_address, uint256 m_amount) external;
    function addMinter(address minter_address) external;
    function removeMinter(address minter_address) external;

    /// @dev restricted functions (timelock)
    function setTimelock(address _timelock_address) external;

    /// @dev events
    event Burn(address indexed account, uint256 amount);
    event Mint(address indexed account, uint256 amount);
    event MinterAdded(address indexed minter_address);
    event MinterRemoved(address indexed minter_address);
    event TimelockChanged(address timelock_address);
    event TokenMinterBurned(address indexed from, address indexed to, uint256 amount);
    event TokenMinterMinted(address indexed from, address indexed to, uint256 amount);
}
