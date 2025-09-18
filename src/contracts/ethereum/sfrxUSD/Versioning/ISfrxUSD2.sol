pragma solidity ^0.8.0;

import { ILinearRewardsErc4626_2 } from "src/contracts/ethereum/sfrxUSD/inherited/ILinearRewardsErc4626_2.sol";
import { ITimelock2Step } from "frax-std/access-control/v2/interfaces/ITimelock2Step.sol";
import { IMinter } from "src/contracts/interfaces/IMinter.sol";

interface ISfrxUSD2 is ILinearRewardsErc4626_2, ITimelock2Step, IMinter {
    // views
    function version() external view returns (string memory);

    // state changers
    function burn(uint256 _amount) external;
    function setAllPricingParams(
        uint256 _newPricePerShareStored,
        uint256 _newPricePerShareIncPerSecond,
        uint256 _newLastSync
    ) external;
    function setPricePerShareIncPerSecond(uint256 _newPricePerShareIncPerSecond) external;
    function setPricePerShareStored(uint256 _newPricePerShareStored) external;

    // errors
    error MustNotBeInTheFuture();

    // events
    event Burn(address indexed from, uint256 amount);
    event SetLastSync(uint256 newLastSync);
    event SetPricePerShareIncPerSecond(uint256 newPricePerShareIncPerSecond);
    event SetPricePerShareStored(uint256 newPricePerShareStored);
}
