pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts-5.3.0/token/ERC20/ERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts-5.3.0/token/ERC20/extensions/IERC20Permit.sol";
import { IERC20Burnable } from "src/contracts/interfaces/IERC20Burnable.sol";
import { IMinter } from "src/contracts/interfaces/IMinter.sol";

/// @title FrxUSD interface
interface IFrxUSD1 is IERC20, IERC20Permit, IERC20Burnable, IMinter {
    function initialize(address _owner, string memory _name, string memory _symbol) external;

    /* ========== EVENTS ========== */

    /// @notice Emitted whenever the bridge burns tokens from an account
    /// @param account Address of the account tokens are being burned from
    /// @param amount  Amount of tokens burned
    event Burn(address indexed account, uint256 amount);

    /// @notice Emitted whenever the bridge mints tokens to an account
    /// @param account Address of the account tokens are being minted for
    /// @param amount  Amount of tokens minted.
    event Mint(address indexed account, uint256 amount);
}
