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

        // These contracts are all based on the same architecture and should be initialized with their own respective values

        // sfrxUSD
        new ERC20PPNBMInitializable();
        // sfrxETH
        new ERC20PPNBMInitializable();
        // FPI
        new ERC20PPNBMInitializable();
        // frxBTC
        new ERC20PPNBMInitializable();

        vm.stopBroadcast();
    }
}
