pragma solidity ^0.8.0;

interface IERC20Burnable {
    function burn(uint256 value) external;
    function burnFrom(address account, uint256 value) external;
}
