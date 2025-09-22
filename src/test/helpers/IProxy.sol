// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IProxy {
    function owner() external view returns (address);
    function upgradeToAndCall(address, bytes memory) external;
    function upgradeAndCall(address, address, bytes memory) external;
    function upgrade(address, address) external;
}
