pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { FrxETH } from "src/contracts/fraxtal/frxETH/FrxETH.sol";
import { WFRAX } from "src/contracts/fraxtal/wfrax/WFRAX.sol";
import { FrxUSDInitializable } from "src/contracts/fraxtal-testnet/frxUSD/FrxUSDInitializable.sol";

import { ERC20PPNBMInitializable } from "src/contracts/fraxtal-testnet/shared/ERC20PPNBMInitializable.sol";

contract DeployImps is Script {
    function run() public {
        vm.startBroadcast();

        // These contracts are unique and have their own state

        new WFRAX();
        new FrxETH();
        new FrxUSDInitializable();

        // These contracts are all based on the same architecture and should be initialized with the same values of construction

        // sfrxUSD
        new ERC20PPNBMInitializable("Staked Frax USD", "1");
        // sfrxETH
        new ERC20PPNBMInitializable("Staked Frax Ether", "1");
        // FPI
        new ERC20PPNBMInitializable("Frax Price Index", "1");
        // frxBTC
        new ERC20PPNBMInitializable("Frax Bitcoin", "1");

        vm.stopBroadcast();
    }
}
