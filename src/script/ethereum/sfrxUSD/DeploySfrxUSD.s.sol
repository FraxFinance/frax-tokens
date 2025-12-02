pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { console } from "frax-std/FraxTest.sol";

import { SfrxUSD } from "src/contracts/ethereum/sfrxUSD/SfrxUSD.sol";

import { SafeTx, SafeTxHelper } from "frax-std/SafeTxHelper.sol";

import { ProxyAdmin, ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

address constant SFRXUSD_PROXY = 0xcf62F905562626CfcDD2261162a51fd02Fc9c5b6;

// forge script src/script/DeploySfrxUSD.s.sol --rpc-url https://eth-mainnet.public.blastapi.io (TODO: verifier)
contract DeploySfrxUSD is BaseScript {
    address public frxUsd = 0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29; // frxUSD proxy address
    address public proxyAdmin;
    address public owner;
    address public implementation;
    SafeTx[] public msigTxs;
    SafeTxHelper public safeTxHelper;

    bool public isTest = false;

    function setUp() public override {
        bytes32 adminSlot = vm.load(SFRXUSD_PROXY, ERC1967Utils.ADMIN_SLOT);
        proxyAdmin = address(uint160(uint256(adminSlot)));
        owner = ProxyAdmin(proxyAdmin).owner();

        safeTxHelper = new SafeTxHelper();
    }

    function run() public {
        deploySfrxUSD();
        generateMsigTx();
    }

    function runTest() public {
        isTest = true;
        run();
    }

    function deploySfrxUSD() public broadcaster {
        implementation = address(new SfrxUSD(frxUsd));
        require(implementation != address(0));
    }

    function generateMsigTx() public {
        // bytes memory initData = abi.encodeWithSignature("initialize()");
        bytes memory upgradeData = abi.encodeCall(
            ProxyAdmin.upgradeAndCall,
            (ITransparentUpgradeableProxy(payable(SFRXUSD_PROXY)), implementation, hex"")
        );
        vm.prank(owner);
        (bool success, ) = proxyAdmin.call(upgradeData);
        require(success, "Upgrade failed");

        msigTxs.push(SafeTx({ name: "upgrade", to: proxyAdmin, value: 0, data: upgradeData }));

        if (isTest) return; // skip writing to file

        // write to file
        string memory root = vm.projectRoot();
        string memory filename = string.concat(root, "/src/script/ethereum/sfrxUSD/DeploySfrxUSD.json");
        safeTxHelper.writeTxs(msigTxs, filename);
    }
}
