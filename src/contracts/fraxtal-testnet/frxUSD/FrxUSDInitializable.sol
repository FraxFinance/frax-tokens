pragma solidity ^0.8.0;

import { FrxUSD } from "src/contracts/fraxtal/frxUSD/FrxUSD.sol";
import { Initializable } from "@openzeppelin/contracts-5.2.0/proxy/utils/Initializable.sol";

contract FrxUSDInitializable is FrxUSD, Initializable {
    constructor() FrxUSD() {
        _disableInitializers();
    }

    function initialize(address _owner, address _timelock) external initializer {
        assembly {
            // _name (slot 3): "Frax USD" (8 bytes, length * 2 = 0x10)
            sstore(3, 0x4672617820555344000000000000000000000000000000000000000000000010)

            // _symbol (slot 4): "frxUSD" (6 bytes, length * 2 = 0x0c)
            sstore(4, 0x667278555344000000000000000000000000000000000000000000000000000c)

            // owner (slot 8)
            sstore(8, _owner)

            // timelock_address (slot 10)
            sstore(10, _timelock)
        }
    }
}
