// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20PermitPermissionedOptiMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedOptiMintable.sol";

/// @title ERC20PermitPermissionedNonBridgeableMintable
/// @notice A native ERC20 token that cannot be bridged via the native bridge
contract ERC20PermitPermissionedNonBridgeableMintable is ERC20PermitPermissionedOptiMintable {
    /// @custom:semver 1.0.0
    function version() public pure override returns (string memory) {
        return "1.0.0";
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20PermitPermissionedOptiMintable(address(0), address(0), address(0), address(0), _name, _symbol) {}

    function mint(address, uint256) external pure override {
        revert Deprecated();
    }

    function burn(address, uint256) external pure override {
        revert Deprecated();
    }

    error Deprecated();
}
