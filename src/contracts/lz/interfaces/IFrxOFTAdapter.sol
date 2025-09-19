pragma solidity ^0.8.0;

import { IOFT } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/oft/interfaces/IOFT.sol";
import { IOAppCore } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/oapp/interfaces/IOAppCore.sol";
import { IOAppComposer } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/oapp/interfaces/IOAppComposer.sol";
import { IOAppOptionsType3 } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import { IOAppPreCrimeSimulator } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/precrime/interfaces/IOAppPreCrimeSimulator.sol";

/// @title IFrxOFTAdapter
/// @notice Interface for the FrxOFTAdapter contract
interface IFrxOFTAdapter is IOFT, IOAppCore, IOAppComposer, IOAppOptionsType3, IOAppPreCrimeSimulator {
    function version() external pure returns (uint256 major, uint256 minor, uint256 patch);
}
