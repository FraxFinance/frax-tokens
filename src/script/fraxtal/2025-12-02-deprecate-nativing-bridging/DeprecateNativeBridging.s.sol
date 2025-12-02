pragma solidity ^0.8.0;

import { BaseScript } from "frax-std/BaseScript.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { ProxyAdmin, ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { console } from "forge-std/console.sol";

import { FrxUSD } from "src/contracts/fraxtal/frxUSD/FrxUSD.sol";
import { SfrxUSD } from "src/contracts/fraxtal/sfrxUSD/SfrxUSD.sol";
import { FPI } from "src/contracts/fraxtal/fpi/FPI.sol";
import { FrxBTC } from "src/contracts/fraxtal/frxBTC/FrxBTC.sol";
import { FrxETH } from "src/contracts/fraxtal/frxETH/FrxETH.sol";
import { SfrxETH } from "src/contracts/fraxtal/sfrxETH/SfrxETH.sol";

import { SafeTx, SafeTxHelper } from "frax-std/SafeTxHelper.sol";

address constant FRXUSD_PROXY = 0xFc00000000000000000000000000000000000001;
address constant SFRXUSD_PROXY = 0xfc00000000000000000000000000000000000008;
address constant FPI_PROXY = 0xFc00000000000000000000000000000000000003;
address constant FRXBTC_PROXY = 0xfC00000000000000000000000000000000000007;
address constant FRXETH_PROXY = 0xFC00000000000000000000000000000000000006;
address constant SFRXETH_PROXY = 0xFC00000000000000000000000000000000000005;

// forge script src/script/fraxtal/2025-12-02-deprecate-nativing-bridging/DeprecateNativeBridging.s.sol --rpc-url https://rpc.frax.com TODO: verify
contract DeprecateNativeBridging is BaseScript {
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

        super.setUp();
    }

    function run() public {
        deployAndUpgradeFrxUsd();
        deployAndUpgradeSfrxUsd();
        deployAndUpgradeFpi();
        deployAndUpgradeFrxBtc();
        deployAndUpgradeFrxEth();
        deployAndUpgradeSfrxEth();

        if (!isTest) generateMsigTx();
    }

    function runTest() public {
        isTest = true;
        run();
    }

    function deployAndUpgradeFrxUsd() public {
        vm.startBroadcast(deployer);
        implementation = address(new FrxUSD());
        require(implementation != address(0), "Failed implementation");
        vm.stopBroadcast();

        upgrade(FRXUSD_PROXY);
    }

    function deployAndUpgradeSfrxUsd() public {
        vm.startBroadcast(deployer);
        implementation = address(new SfrxUSD());
        require(implementation != address(0), "Failed implementation");
        vm.stopBroadcast();

        upgrade(SFRXUSD_PROXY);
    }

    function deployAndUpgradeFpi() public {
        vm.startBroadcast(deployer);
        implementation = address(new FPI());
        require(implementation != address(0), "Failed implementation");
        vm.stopBroadcast();

        upgrade(FPI_PROXY);
    }

    function deployAndUpgradeFrxBtc() public {
        vm.startBroadcast(deployer);
        implementation = address(new FrxBTC());
        require(implementation != address(0), "Failed implementation");
        vm.stopBroadcast();

        upgrade(FRXBTC_PROXY);
    }

    function deployAndUpgradeFrxEth() public {
        vm.startBroadcast(deployer);
        implementation = address(new FrxETH());
        require(implementation != address(0), "Failed implementation");
        vm.stopBroadcast();

        upgrade(FRXETH_PROXY);
    }

    function deployAndUpgradeSfrxEth() public {
        vm.startBroadcast(deployer);
        implementation = address(new SfrxETH());
        require(implementation != address(0), "Failed implementation");
        vm.stopBroadcast();

        upgrade(SFRXETH_PROXY);
    }

    function upgrade(address proxy) public {
        string memory symbolBefore = IERC20Metadata(proxy).symbol();

        bytes memory initializeData = abi.encodeWithSignature("totalSupply()");
        bytes memory upgradeData = abi.encodeCall(
            ProxyAdmin.upgradeAndCall,
            (ITransparentUpgradeableProxy(payable(proxy)), implementation, initializeData)
        );
        vm.prank(owner);
        (bool success, ) = proxyAdmin.call(upgradeData);
        require(success, "Upgrade failed");

        txs.push(SafeTx({ name: "upgrade", to: proxyAdmin, value: 0, data: upgradeData }));

        string memory symbolAfter = IERC20Metadata(proxy).symbol();
        require(keccak256(bytes(symbolBefore)) == keccak256(bytes(symbolAfter)), "Symbol changed");
    }

    function generateMsigTx() public {
        string memory root = vm.projectRoot();
        string memory filename = string.concat(
            root,
            "/src/script/fraxtal/2025-12-02-deprecate-nativing-bridging/DeprecateNativeBridging.json"
        );
        txHelper.writeTxs(txs, filename);

        console.log("Deploy msig tx from %s", owner);
    }
}
