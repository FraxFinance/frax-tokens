pragma solidity ^0.8.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts-5.3.0/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts-5.3.0/token/ERC20/extensions/IERC20Metadata.sol";
import { UD60x18 } from "@prb/math/src/ud60x18/ValueType.sol";

interface ILinearRewardsErc4626_2 is IERC20, IERC20Metadata {
    // structs
    struct RewardsCycleData {
        uint40 cycleEnd;
        uint40 lastSync;
        uint216 rewardCycleAmount;
    }

    // state variables
    function PRECISION() external view returns (uint256);
    function ONE_YEAR() external view returns (uint256);
    function REWARDS_CYCLE_LENGTH() external view returns (uint256);
    function ONE_YEAR_UD60X18() external view returns (UD60x18);
    function pricePerShareStored() external view returns (uint256);
    function pricePerShareIncPerSecond() external view returns (uint256);
    function lastSync() external view returns (uint256);
    function asset() external view returns (ERC20);

    // views
    function calcPPSIPSForGivenAPY(uint256 _apyE18) external view returns (uint256 _newPPSIPS);
    function previewTotalAssets() external view returns (uint256 _newTotalAssets);
    function storedTotalAssets() external view returns (uint256 _newTotalAssets);
    function previewTotalAssetsFuture(uint256 _futureTime) external view returns (uint256 _newTotalAssets);
    function previewPricePerShare() external view returns (uint256 _newPricePerShare);
    function previewPricePerShareFuture(uint256 _futureTime) external view returns (uint256 _newPricePerShare);
    function previewPPSAndTotalAssets() external view returns (uint256 _pricePerShare, uint256 _totalAssets);
    function pricePerShare() external view returns (uint256 _pricePerShare);
    function totalAssets() external view returns (uint256);
    function lastRewardsDistribution() external view returns (uint256);

    // deprecated views
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
    function maxDistributionPerSecondPerAsset() external view returns (uint256);
    function rewardsCycleData() external view returns (RewardsCycleData memory);

    // state changers
    function sync() external returns (uint256 _pricePerShare);

    // deprecated state changers
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

    // errors
    error UnderlyingAssetMustBe18Decimals();
    error InvalidAPY();
    error MintRedeemsDisabled();
}
