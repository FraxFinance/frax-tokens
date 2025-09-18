// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================= FrxUSD ===============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance
// Tested for 18-decimal underlying assets only

import { FrxUSD2 } from "src/contracts/ethereum/frxUSD/Versioning/FrxUSD2.sol";

contract FrxUSD is FrxUSD2 {
    constructor(
        address _ownerAddress,
        string memory _name,
        string memory _symbol
    ) FrxUSD2(_ownerAddress, _name, _symbol) {}
}
