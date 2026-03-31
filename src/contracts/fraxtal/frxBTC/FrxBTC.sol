pragma solidity ^0.8.0;

import { ERC20PermitPermissionedNonBridgeableMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedNonBridgeableMintable.sol";

contract FrxBTC is ERC20PermitPermissionedNonBridgeableMintable {
    constructor() ERC20PermitPermissionedNonBridgeableMintable("Frax Bitcoin", "frxBTC") {}
}
