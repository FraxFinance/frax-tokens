// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { ERC20PermitPermissionedNonBridgeableMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedNonBridgeableMintable.sol";

contract SfrxETH is ERC20PermitPermissionedNonBridgeableMintable {
    constructor() ERC20PermitPermissionedNonBridgeableMintable("Staked Frax Ether", "sfrxETH") {}
}
