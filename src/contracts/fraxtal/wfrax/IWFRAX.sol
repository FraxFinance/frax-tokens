pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts-5.2.0/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts-5.2.0/token/ERC20/extensions/IERC20Permit.sol";
import { IERC5267 } from "@openzeppelin/contracts-5.2.0/interfaces/IERC5267.sol";
import { ISemver } from "src/contracts/fraxtal/shared/interfaces/ISemver.sol";

interface IWFRAX is IERC20, IERC20Permit, IERC5267, ISemver {
    /// @dev functions
    function burn(uint256 _value) external;
    function donate() external payable;
    function deposit() external payable;
    function withdraw(uint256 wad) external;

    /// @dev errors
    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSignature();

    /// @dev events
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}
