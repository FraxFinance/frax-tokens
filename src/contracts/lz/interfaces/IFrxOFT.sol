pragma solidity ^0.8.0;

import { IOFT } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/oft/interfaces/IOFT.sol";
import { IOAppCore } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/oapp/interfaces/IOAppCore.sol";
import { IOAppComposer } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/oapp/interfaces/IOAppComposer.sol";
import { IOAppOptionsType3 } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import { IOAppPreCrimeSimulator } from "@fraxfinance/layerzero-v2-upgradeable/oapp/contracts/precrime/interfaces/IOAppPreCrimeSimulator.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IFrxOFT
/// @notice Interface for the FrxOFT contract
interface IFrxOFT is IOFT, IERC20, IOAppCore, IOAppComposer, IOAppPreCrimeSimulator, IOAppOptionsType3 {
    function version() external pure returns (uint256 major, uint256 minor, uint256 patch);
    function initialize(string memory _name, string memory _symbol, address _delegate) external;
}
