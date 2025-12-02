pragma solidity ^0.8.0;

import { ERC20PermitPermissionedNonBridgeableMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedNonBridgeableMintable.sol";

contract SfrxUSD is ERC20PermitPermissionedNonBridgeableMintable {
    function version() public pure virtual override returns (string memory) {
        return "1.1.0";
    }

    constructor() ERC20PermitPermissionedNonBridgeableMintable("Staked Frax USD", "sfrxUSD") {}
}
