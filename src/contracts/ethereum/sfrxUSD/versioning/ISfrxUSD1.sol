pragma solidity ^0.8.0;

import { ILinearRewardsErc4626 } from "src/contracts/ethereum/sfrxUSD/inherited/ILinearRewardsErc4626.sol";
import { ITimelock2Step } from "frax-std/access-control/v2/interfaces/ITimelock2Step.sol";

interface ISfrxUSD is ILinearRewardsErc4626, ITimelock2Step {
    // state variables
    function maxDistributionPerSecondPerAsset() external view returns (uint256);
    function version() external view returns (string memory);
    function setMaxDistributionPerSecondPerAsset(uint256 _maxDistributionPerSecondPerAsset) external;
    function calculateRewardsToDistribute(
        RewardsCycleData memory _rewardsCycleData,
        uint256 _deltatime
    ) external view returns (uint256 _rewardToDistribute);

    event SetMaxDistributionPerSecondPerAsset(uint256 oldMax, uint256 newMax);

    error AlreadyInitialized();
}
