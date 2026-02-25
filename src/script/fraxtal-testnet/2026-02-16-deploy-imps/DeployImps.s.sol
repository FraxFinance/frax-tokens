pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import { FrxETH } from "src/contracts/fraxtal/frxETH/FrxETH.sol";
import { WFRAX } from "src/contracts/fraxtal/wfrax/WFRAX.sol";
import { FrxUSDInitializable } from "src/contracts/fraxtal-testnet/frxUSD/FrxUSDInitializable.sol";

import { ERC20PPNBMInitializable } from "src/contracts/fraxtal-testnet/shared/ERC20PPNBMInitializable.sol";
import { ERC20PPOMInitializable } from "src/contracts/fraxtal-testnet/shared/ERC20PPOMInitializable.sol";

// forge script --rpc-url https://rpc.testnet.frax.com src/script/fraxtal-testnet/2026-02-16-deploy-imps/DeployImps.s.sol --broadcast --verify --verifier custom --gcp
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

        // FPIS
        new ERC20PPOMInitializable(
            0x4200000000000000000000000000000000000010,
            0xC3cffC81cE1c80bB9FC9BB441B77461a9689E332
        );

        vm.stopBroadcast();
    }
}
