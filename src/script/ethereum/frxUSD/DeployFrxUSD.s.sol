pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { ProxyAdmin, ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { console } from "forge-std/console.sol";

import { FrxUSD } from "src/contracts/ethereum/frxUSD/FrxUSD.sol";

import { SafeTx, SafeTxHelper } from "frax-std/SafeTxHelper.sol";

address constant FRXUSD_PROXY = 0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29;

// forge script src/script/ethereum/frxUSD/DeployFrxUSD.s.sol --rpc-url https://eth-mainnet.public.blastapi.io TODO: verify
contract DeployFrxUSD is BaseScript {
    address public proxyAdmin;
    address public owner;
    address public implementation;
    SafeTx[] public txs;
    SafeTxHelper public txHelper;

    bool public isTest = false;

    function setUp() public override {
        bytes32 adminSlot = vm.load(FRXUSD_PROXY, ERC1967Utils.ADMIN_SLOT);
        proxyAdmin = address(uint160(uint256(adminSlot)));
        owner = ProxyAdmin(proxyAdmin).owner();

        txHelper = new SafeTxHelper();
    }

    function run() public {
        deployFrxUsd();
        generateMsigTx();
    }

    function runTest() public {
        isTest = true;
        run();
    }

    function deployFrxUsd() public broadcaster {
        implementation = address(new FrxUSD());
        require(implementation != address(0), "Failed implementation");
    }

    function generateMsigTx() public {
        bytes memory initializeData = abi.encodeWithSignature("totalSupply()");
        bytes memory upgradeData = abi.encodeCall(
            ProxyAdmin.upgradeAndCall,
            (ITransparentUpgradeableProxy(payable(FRXUSD_PROXY)), implementation, initializeData)
        );
        vm.prank(owner);
        (bool success, ) = proxyAdmin.call(upgradeData);
        require(success, "Upgrade failed");

        if (isTest) return; // skip writing to file in test mode

        txs.push(SafeTx({ name: "upgrade", to: proxyAdmin, value: 0, data: upgradeData }));
        string memory root = vm.projectRoot();
        string memory filename = string.concat(root, "/src/script/ethereum/frxUSD/DeployFrxUSD.json");
        txHelper.writeTxs(txs, filename);

        console.log("Deploy msig tx from %s", owner);
    }
}
