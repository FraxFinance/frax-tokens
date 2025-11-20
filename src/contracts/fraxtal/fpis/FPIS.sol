pragma solidity ^0.8.0;

import { ERC20PermitPermissionedOptiMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedOptiMintable.sol";

contract FPIS is ERC20PermitPermissionedOptiMintable {
    /// @param _bridge Address of the L2 standard bridge
    /// @param _remoteToken Address of the corresponding L1 token
    constructor(
        address _bridge,
        address _remoteToken
    ) ERC20PermitPermissionedOptiMintable(_bridge, _remoteToken, "Frax Price Index Share", "FPIS") {}
}
