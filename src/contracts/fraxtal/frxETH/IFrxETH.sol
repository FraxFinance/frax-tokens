pragma solidity ^0.8.0;

import { IERC20PermitPermissionedOptiMintable } from "src/contracts/fraxtal/shared/interfaces/IERC20PermitPermissionedOptiMintable.sol";

interface IFrxETH is IERC20PermitPermissionedOptiMintable {
    function adjustTotalSupply(int256 _newTotalSupplyDiff) external;
}
