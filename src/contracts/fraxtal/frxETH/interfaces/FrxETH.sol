pragma solidity ^0.8.0;

import { IERC20Permit } from "@openzeppelin/contracts-5.2.0/token/ERC20/extensions/IERC20Permit.sol";
import { IERC20 } from "@openzeppelin/contracts-5.2.0/token/ERC20/IERC20.sol";
import { IERC5267 } from "@openzeppelin/contracts-5.2.0/interfaces/IERC5267.sol";

interface IWfrxETH is IERC20Permit, IERC20, IERC5267 {
    function deposit() external payable;
    function withdraw(uint256) external;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}
