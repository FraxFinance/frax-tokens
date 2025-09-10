pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts-5.3.0/token/ERC20/ERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts-5.3.0/token/ERC20/extensions/IERC20Permit.sol";

/// @title FrxUSD interface
interface IFrxUSD is IERC20, IERC20Permit {
    function minters_array(uint256) external view returns (address);
    function minters(address) external view returns (bool);
    function initialize(address _owner, string memory _name, string memory _symbol) external;
    function minter_burn_from(address b_address, uint256 b_amount) external;
    function minter_mint(address m_address, uint256 m_amount) external;
    function addMinter(address minter_address) external;
    function removeMinter(address minter_address) external;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the bridge burns tokens from an account
    /// @param account Address of the account tokens are being burned from
    /// @param amount  Amount of tokens burned
    event Burn(address indexed account, uint256 amount);

    /// @notice Emitted whenever the bridge mints tokens to an account
    /// @param account Address of the account tokens are being minted for
    /// @param amount  Amount of tokens minted.
    event Mint(address indexed account, uint256 amount);

    /// @notice Emitted when a non-bridge minter is added
    /// @param minter_address Address of the new minter
    event MinterAdded(address minter_address);

    /// @notice Emitted when a non-bridge minter is removed
    /// @param minter_address Address of the removed minter
    event MinterRemoved(address minter_address);

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
}
