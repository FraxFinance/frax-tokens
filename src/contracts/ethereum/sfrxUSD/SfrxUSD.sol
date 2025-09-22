// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== StakedFrxUSD ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance
// Tested for 18-decimal underlying assets only

import { SfrxUSD2, IERC20 } from "src/contracts/ethereum/sfrxUSD/versioning/SfrxUSD2.sol";

contract SfrxUSD is SfrxUSD2 {
    constructor(
        IERC20 _underlying,
        string memory _name,
        string memory _symbol,
        address _timelockAddress
    ) SfrxUSD2(_underlying, _name, _symbol, _timelockAddress) {}
}
