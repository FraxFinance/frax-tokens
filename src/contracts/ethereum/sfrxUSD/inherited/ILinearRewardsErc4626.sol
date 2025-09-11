pragma solidity ^0.8.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts-5.3.0/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts-5.3.0/token/ERC20/extensions/IERC20Metadata.sol";

interface ILinearRewardsErc4626 is IERC20, IERC20Metadata {
    // structs
    struct RewardsCycleData {
        uint40 cycleEnd;
        uint40 lastSync;
        uint216 rewardCycleAmount;
    }

    // state variables
    function PRECISION() external view returns (uint256);
    function REWARDS_CYCLE_LENGTH() external view returns (uint256);
    function rewardsCycleData() external view returns (RewardsCycleData memory);
    function lastRewardsDistribution() external view returns (uint256);
    function storedTotalAssets() external view returns (uint256);
    function UNDERLYING_PRECISION() external view returns (uint256);
    function asset() external view returns (ERC20);

    // views
    function pricePerShare() external view returns (uint256);
    function calculateRewardsToDistribute(
        RewardsCycleData memory _rewardsCycleData,
        uint256 _deltaTime
    ) external view returns (uint256 _rewardToDistribute);
    function previewDistributeRewards() external view returns (uint256);
    function previewSyncRewards() external view returns (RewardsCycleData memory);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function previewMint(uint256 shares) external view returns (uint256 assets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);

    // state changers
    function syncRewardsAndDistribution() external;
    function deposit(uint256 _assets, address _receiver) external returns (uint256 _shares);
    function mint(uint256 _shares, address _receiver) external returns (uint256 _assets);
    function withdraw(uint256 _assets, address _receiver, address _owner) external returns (uint256 _shares);
    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 _assets);
    function depositWithSignature(
        uint256 _assets,
        address _receiver,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (uint256 _shares);

    // events
    event SyncRewards(uint40 cycleEnd, uint40 lastSync, uint216 rewardCycleAmount);
    event DistributeRewards(uint256 rewardsToDistribute);
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
}
