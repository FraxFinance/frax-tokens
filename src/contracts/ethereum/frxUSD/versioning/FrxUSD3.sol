//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { FrxUSD2, ERC20, EIP712, Nonces, ERC20Permit } from "src/contracts/ethereum/frxUSD/versioning/FrxUSD2.sol";
import { PermitModule } from "src/contracts/shared/core/modules/PermitModule.sol";
import { EIP3009Module, SignatureModule } from "src/contracts/shared/core/modules/EIP3009Module.sol";

/// @title FrxUSD v3.0.0
/// @notice Frax USD Stablecoin by Frax Finance
/// @dev v3.0.0 adds ERC-1271 and EIP-3009 support
contract FrxUSD3 is FrxUSD2, EIP3009Module, PermitModule {
    constructor() FrxUSD2(address(1), "Frax USD", "frxUSD") {}

    /*//////////////////////////////////////////////////////////////
                        Module Overrides
    //////////////////////////////////////////////////////////////*/

    function __transfer(address from, address to, uint256 amount) internal override returns (bool) {
        ERC20._transfer(from, to, amount);
        return true;
    }

    function __hashTypedDataV4(bytes32 structHash) internal view override(SignatureModule) returns (bytes32) {
        return EIP712._hashTypedDataV4(structHash);
    }

    function __approve(address owner, address spender, uint256 amount) internal override(PermitModule) {
        ERC20._approve(owner, spender, amount);
    }

    function __useNonce(address owner) internal override(PermitModule) returns (uint256) {
        return Nonces._useNonce(owner);
    }

    function __domainSeparatorV4() internal view override(PermitModule) returns (bytes32) {
        return EIP712._domainSeparatorV4();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override(ERC20Permit, PermitModule) {
        return
            PermitModule.permit({ owner: owner, spender: spender, value: value, deadline: deadline, v: v, r: r, s: s });
    }
}
