// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/FraxTest.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { FrxUSD } from "src/contracts/fraxtal/frxUSD/FrxUSD.sol";
import { IFrxUSD } from "src/contracts/fraxtal/frxUSD/IFrxUSD.sol";
import { IProxy } from "src/test/helpers/IProxy.sol";
import { SigUtils } from "src/test/utils/SigUtils.sol";
import { EIP3009Module } from "src/contracts/shared/core/modules/EIP3009Module.sol";
import { IERC165 } from "@openzeppelin/contracts-5.2.0/utils/introspection/IERC165.sol";
import { IOptimismMintableERC20 } from "src/contracts/fraxtal/shared/interfaces/IOptimismMintableERC20.sol";
import { ILegacyMintableERC20 } from "src/contracts/fraxtal/shared/interfaces/ILegacyMintableERC20.sol";
import "src/Constants.sol" as Constants;

contract FrxUSD_Fraxtal_Compliance is FraxTest {
    FrxUSD public constant frxusd = FrxUSD(0xFc00000000000000000000000000000000000001);
    FrxUSD public implV2;
    SigUtils public sigUtils;

    uint256 alPrivateKey = 0x42;
    address al;
    address bob = address(0xb0b);
    address carl = address(0xca71);
    address alice = address(0xa11ce);
    address badActor = address(0xbadbeef);

    address[] targets;
    uint256[] amounts;

    bytes32[] frxusdStorageLayoutInitial;

    // EIP-3009 test parameters
    bytes32 eip3009Nonce = bytes32(abi.encode(1));
    uint256 validAfter;
    uint256 validBefore;

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("FRAXTAL_MAINNET_URL"));

        al = vm.addr(alPrivateKey);

        /// @notice needed to register under coverage report
        // implV2 = FrxUSD(deployFrxUsdImplementationFraxtal());
        implV2 = FrxUSD(0x0000000083BDf23788585D499EAb0D92A8bEfB1D);
        // implV2 = new FrxUSD(
        //     address(0x4200000000000000000000000000000000000010),
        //     address(0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29)
        // );
        deal(address(frxusd), al, 5000e18);
        deal(address(frxusd), bob, 15e18);
        deal(address(frxusd), carl, 69e18);

        // Ensure al is an EOA for signature tests
        vm.etch(al, hex"");

        validAfter = block.timestamp - 1;
        validBefore = block.timestamp + 1 days;
    }

    function test_assert_balances_remain_constant() public {
        _upgradeFrxUSD();
        assertEq({ left: frxusd.balanceOf(al), right: 5000e18, err: "// THEN: balance not constant" });
        assertEq({ left: frxusd.balanceOf(bob), right: 15e18, err: "// THEN: balance not constant" });
        assertEq({ left: frxusd.balanceOf(carl), right: 69e18, err: "// THEN: balance not constant" });
        assertEq({ left: frxusd.balanceOf(alice), right: 0, err: "// THEN: balance not constant" });
    }

    function test_storage_layout_remains_constant() public {
        for (uint256 i; i < 20; i++) {
            bytes32 slotVal = vm.load(address(frxusd), bytes32(uint256(i)));
            frxusdStorageLayoutInitial.push(slotVal);
        }
        _upgradeFrxUSD();

        // check that all slots match
        for (uint256 i; i < 20; i++) {
            bytes32 slotVal = vm.load(address(frxusd), bytes32(uint256(i)));
            assertEq({ left: frxusdStorageLayoutInitial[i], right: slotVal, err: "// THEN: slot value not expected" });
        }
    }

    function test_storage_layout_change_when_paused() public {
        for (uint256 i; i < 20; i++) {
            bytes32 slotVal = vm.load(address(frxusd), bytes32(uint256(i)));
            frxusdStorageLayoutInitial.push(slotVal);
        }
        test_upgrade_and_pause_successful();

        // check that all slots less slot #12 match
        for (uint256 i; i < 20; i++) {
            bytes32 slotVal = vm.load(address(frxusd), bytes32(uint256(i)));
            if (i != 14) {
                assertEq({
                    left: frxusdStorageLayoutInitial[i],
                    right: slotVal,
                    err: "// THEN: slot value not expected"
                });
            } else {
                assertEq({ left: bytes32(uint256(1)), right: slotVal, err: "// THEN: slot value not expected" });
            }
        }
    }

    function test_transfer() public {
        _upgradeFrxUSD();

        uint256 balAliceBefore = frxusd.balanceOf(alice);
        uint256 balAlBefore = frxusd.balanceOf(al);

        vm.prank(al);
        frxusd.transfer(alice, 100e18);

        uint256 balAliceAfter = frxusd.balanceOf(alice);
        uint256 balAlAfter = frxusd.balanceOf(al);

        assertEq({ right: balAlBefore - balAlAfter, left: 100e18, err: "// THEN: balance change of al not expected" });

        assertEq({
            right: balAliceAfter - balAliceBefore,
            left: 100e18,
            err: "// THEN: balance change of alice not expected"
        });
    }

    function test_transfer_too_much() public {
        _upgradeFrxUSD();

        uint256 balAliceBefore = frxusd.balanceOf(alice);
        uint256 balAlBefore = frxusd.balanceOf(al);

        vm.prank(al);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)",
                address(al),
                uint256(5000e18),
                uint256(100_000e18)
            )
        );
        frxusd.transfer(alice, 100_000e18);

        uint256 balAliceAfter = frxusd.balanceOf(alice);
        uint256 balAlAfter = frxusd.balanceOf(al);

        assertEq({ right: balAlBefore - balAlAfter, left: 0, err: "// THEN: balance change of al not expected" });
        assertEq({
            right: balAliceAfter - balAliceBefore,
            left: 0,
            err: "// THEN: balance change of alice not expected"
        });
    }

    function test_transfer_when_paused_reverts() public {
        test_upgrade_and_pause_successful();

        vm.prank(al);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.transfer(alice, 1e18);
    }

    function test_transferFrom_when_paused_revert() public {
        vm.prank(al);
        frxusd.approve(bob, 10e18);

        test_upgrade_and_pause_successful();

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.transferFrom(al, alice, 1e18);
    }

    function test_upgrade_and_pause_successful() public {
        _upgradeFrxUSD();
        vm.prank(frxusd.owner());
        frxusd.pause();
        assertEq({ left: frxusd.isPaused(), right: true, err: "// THEN: frxusd is not paused" });
    }

    function test_upgrade_and_freeze_successful() public {
        _upgradeAndFreeze(al);
    }

    function test_upgrade_and_freeze_transfer_Reverts() public {
        _upgradeAndFreeze(al);

        vm.prank(al);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.transfer(alice, 100e18);
    }

    function test_upgrade_and_freezeMany() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(carl);

        vm.prank(frxusd.owner());
        frxusd.freezeMany(targets);

        assertEq({ left: frxusd.isFrozen(al), right: true, err: "// THEN: al was not frozen" });
        assertEq({ left: frxusd.isFrozen(carl), right: true, err: "// THEN: carl was not frozen" });
    }

    function test_upgrade_and_freeze_transferFrom_Reverts() public {
        vm.prank(al);
        frxusd.approve(bob, 100e18);

        _upgradeAndFreeze(al);

        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        vm.prank(bob);
        frxusd.transferFrom(al, alice, 100e18);
    }

    function test_can_burn_tokens() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.burnFrxUsd(al, 50e18);

        assertEq({
            left: frxusd.balanceOf(al),
            right: 5000e18 - 50e18,
            err: "// THEN: al's balance not decremented correctly"
        });

        vm.prank(frxusd.owner());
        frxusd.burnFrxUsd(al, 0);
        assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
    }

    function test_can_burnMany_tokens() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(bob);
        targets.push(carl);

        amounts.push(0);
        amounts.push(0);
        amounts.push(0);

        vm.prank(frxusd.owner());
        frxusd.burnMany(targets, amounts);

        assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
        assertEq({ left: frxusd.balanceOf(carl), right: 0, err: "// THEN: carl's balance not decremented correctly" });
        assertEq({ left: frxusd.balanceOf(bob), right: 0, err: "// THEN: bob's balance not decremented correctly" });
    }

    function test_can_burn_tokens_when_frozen() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.freeze(al);

        vm.prank(frxusd.owner());
        frxusd.burnFrxUsd(al, 50e18);

        assertEq({
            left: frxusd.balanceOf(al),
            right: 5000e18 - 50e18,
            err: "// THEN: al's balance not decremented correctly"
        });

        vm.prank(frxusd.owner());
        frxusd.burnFrxUsd(al, 0);
        assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
    }

    function test_can_burnMany_tokens_when_frozen() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(bob);
        targets.push(carl);

        amounts.push(0);
        amounts.push(0);
        amounts.push(0);

        vm.prank(frxusd.owner());
        frxusd.freezeMany(targets);

        vm.prank(frxusd.owner());
        frxusd.burnMany(targets, amounts);

        assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
        assertEq({ left: frxusd.balanceOf(carl), right: 0, err: "// THEN: carl's balance not decremented correctly" });
        assertEq({ left: frxusd.balanceOf(bob), right: 0, err: "// THEN: bob's balance not decremented correctly" });
    }

    function test_can_burn_tokens_when_paused() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.pause();

        vm.prank(frxusd.owner());
        frxusd.burnFrxUsd(al, 50e18);

        assertEq({
            left: frxusd.balanceOf(al),
            right: 5000e18 - 50e18,
            err: "// THEN: al's balance not decremented correctly"
        });

        vm.prank(frxusd.owner());
        frxusd.burnFrxUsd(al, 0);
        assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
    }

    function test_can_burnMany_tokens_when_paused() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(bob);
        targets.push(carl);

        amounts.push(0);
        amounts.push(0);
        amounts.push(0);

        vm.prank(frxusd.owner());
        frxusd.pause();

        vm.prank(frxusd.owner());
        frxusd.burnMany(targets, amounts);

        assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
        assertEq({ left: frxusd.balanceOf(carl), right: 0, err: "// THEN: carl's balance not decremented correctly" });
        assertEq({ left: frxusd.balanceOf(bob), right: 0, err: "// THEN: bob's balance not decremented correctly" });
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>            Pre And Post State Assertions          <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */
    function test_BRIDGE_static() public {
        address bridge = frxusd.BRIDGE();
        _upgradeFrxUSD();
        address bridgePost = frxusd.BRIDGE();
        assertEq({ left: bridge, right: bridgePost, err: "// THEN: bridge not static across upgrades" });
        console.log("BRIDGE: ", bridge);
    }

    function test_decimals_static() public {
        uint8 decimals = frxusd.decimals();
        _upgradeFrxUSD();
        uint8 decimalsPost = frxusd.decimals();
        assertEq({ left: decimals, right: decimalsPost, err: "// THEN: decimals not static across upgrades" });
    }

    function test_l1token_static() public {
        address l1token = frxusd.l1Token();
        _upgradeFrxUSD();
        address l1tokenPost = frxusd.l1Token();
        assertEq({ left: l1token, right: l1tokenPost, err: "// THEN: l1Token not static across upgrade" });
    }

    function test_l2bridge_static() public {
        address l2bridge = frxusd.l2Bridge();
        _upgradeFrxUSD();
        address l2bridgePost = frxusd.l2Bridge();
        assertEq({ left: l2bridge, right: l2bridgePost, err: "// THEN: l2bridge vriable not static across upgrade" });
    }

    function test_name_static() public {
        string memory name = frxusd.name();
        _upgradeFrxUSD();
        string memory namePost = frxusd.name();
        assertEq({ left: name, right: namePost, err: "// THEN: name not static across upgrade" });
    }

    function test_symbol_static() public {
        string memory sy = frxusd.symbol();
        _upgradeFrxUSD();
        string memory syPost = frxusd.symbol();
        assertEq({ left: sy, right: syPost, err: "// THEN: symbol not static across upgrade" });
    }

    function test_bridge_static() public {
        address bridge = frxusd.bridge();
        _upgradeFrxUSD();
        address bridgePost = frxusd.bridge();
        assertEq({ left: bridge, right: bridgePost, err: "// THEN: bridge not static across upgrades" });
        console.log("brdige: ", bridge);
    }

    function test_REMOTE_TOKEN_static() public {
        address remote = frxusd.REMOTE_TOKEN();
        _upgradeFrxUSD();
        address remotePost = frxusd.REMOTE_TOKEN();
        assertEq({ left: remote, right: remotePost, err: "// THEN: remote token not static across upgrade" });
    }

    function test_remote_token_static() public {
        address remote = frxusd.remoteToken();
        _upgradeFrxUSD();
        address remotePost = frxusd.remoteToken();
        assertEq({ left: remote, right: remotePost, err: "// THEN: remote token not static across upgrade" });
    }

    function test_timelock_address_static() public {
        address tl = frxusd.timelock_address();
        _upgradeFrxUSD();
        address tlPost = frxusd.timelock_address();
        assertEq({ left: tl, right: tlPost, err: "// THEN: timelock addre not static across upgrade" });
    }

    function test_allowances_static() public {
        vm.prank(al);
        frxusd.approve(bob, 500e18);

        uint256 allowancePre = frxusd.allowance(al, bob);
        _upgradeFrxUSD();
        uint256 allowancePost = frxusd.allowance(al, bob);
        assertEq({ left: allowancePre, right: allowancePost, err: "// THEN: allowance changed with upgrade" });
        assertEq({ left: allowancePre, right: 500e18, err: "// THEN: allowance not as expected" });
    }

    function test_domain_seperator_static() public {
        bytes32 domain = frxusd.DOMAIN_SEPARATOR();
        _upgradeFrxUSD();
        bytes32 domainPost = frxusd.DOMAIN_SEPARATOR();
        assertEq({ left: domain, right: domainPost, err: "// THEN: domain not static" });
    }

    function test_balanceOf_static() public {
        deal(address(frxusd), al, 250_000e18);
        uint256 balPre = frxusd.balanceOf(al);
        _upgradeFrxUSD();
        uint256 balPost = frxusd.balanceOf(al);
        assertEq({ left: 250_000e18, right: balPre, err: "// THEN: balance initial not expected" });
        assertEq({ left: balPre, right: balPost, err: "// THEN: balance not static" });
    }

    function test_eip712_domain_static() public {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = frxusd.eip712Domain();
        _upgradeFrxUSD();
        (
            bytes1 fieldsPost,
            string memory namePost,
            string memory versionPost,
            uint256 chainIdPost,
            address verifyingContractPost,
            bytes32 saltPost,
            uint256[] memory extensionsPost
        ) = frxusd.eip712Domain();
        assertEq({ left: fields, right: fieldsPost, err: "// THEN: `fields` not static" });
        assertEq({ left: name, right: namePost, err: "// THEN: `name` not static" });
        assertEq({ left: version, right: versionPost, err: "// THEN: `version` not static" });
        assertEq({ left: chainId, right: chainIdPost, err: "// THEN: `chainId` not static" });
        assertEq({
            left: verifyingContract,
            right: verifyingContractPost,
            err: "// THEN: `verifyingContract` not static"
        });
        assertEq({ left: salt, right: saltPost, err: "// THEN: `salt` not static" });
        assertEq({
            left: keccak256(abi.encode(extensions)),
            right: keccak256(abi.encode(extensionsPost)),
            err: "// THEN: extensions not static"
        });
    }

    function test_totalSupply_static() public {
        uint256 pre = frxusd.totalSupply();
        _upgradeFrxUSD();
        uint256 post = frxusd.totalSupply();
        assertEq({ left: pre, right: post, err: "// THEN: total supply changed" });
    }

    function test_nominated_owner_static() public {
        address nOwnerPre = frxusd.nominatedOwner();
        console.log("Nominated Owner Pre: ", nOwnerPre);
        _upgradeFrxUSD();
        address nOwnerPost = frxusd.nominatedOwner();
        console.log("Nominated Owner Post: ", nOwnerPost);
        assertEq(nOwnerPost, nOwnerPre, "// THEN: nominated owner change");
    }

    function test_version_static() public {
        string memory versionPre = frxusd.version();
        console.log("Version Pre: ", versionPre);
        _upgradeFrxUSD();
        string memory versionPost = frxusd.version();
        console.log("Version Post: ", versionPost);

        assertEq(versionPre, versionPost, "// THEN: version not change");
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>            Reversions for admin gated calls          <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_can_burnMany_tokens_reverts_array_mismatch() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(bob);
        targets.push(carl);

        amounts.push(0);
        amounts.push(0);

        vm.prank(frxusd.owner());
        vm.expectRevert(bytes4(keccak256("ArrayMisMatch()")));
        frxusd.burnMany(targets, amounts);
    }

    function test_only_owner_can_pause() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.pause();
    }

    function test_only_owner_can_unpause() public {
        test_upgrade_and_pause_successful();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.unpause();
    }

    function test_only_owner_can_freeze() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert();
        frxusd.freeze(bob);
    }

    function test_only_owner_can_thaw() public {
        test_upgrade_and_freeze_successful();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.thaw(al);
    }

    function test_only_owner_can_freezeMany() public {
        _upgradeFrxUSD();

        targets.push(bob);
        targets.push(carl);

        vm.prank(badActor);
        vm.expectRevert();
        frxusd.freezeMany(targets);
    }

    function test_only_owner_can_thawMany() public {
        test_upgrade_and_freezeMany();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        /// @notice targets array populated w/n `test_upgrade_and_freezeMany`
        frxusd.thawMany(targets);
    }

    function test_only_owner_can_burn() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.burnFrxUsd(al, 0);
    }

    function test_only_owner_can_burnMany() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(carl);
        amounts.push(0);
        amounts.push(0);

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.burnMany(targets, amounts);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>       EIP-3009 Compliance w/ Freeze & Pause          <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_transferWithAuthorization_when_from_frozen_reverts() public {
        _upgradeAndFreeze(al);

        (uint8 v, bytes32 r, bytes32 s) = _signTransferAuthorization(al, bob, 1e18);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.transferWithAuthorization({
            from: al,
            to: bob,
            value: 1e18,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_transferWithAuthorization_when_to_frozen_reverts() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.freeze(bob);

        (uint8 v, bytes32 r, bytes32 s) = _signTransferAuthorization(al, bob, 1e18);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.transferWithAuthorization({
            from: al,
            to: bob,
            value: 1e18,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_transferWithAuthorization_when_paused_reverts() public {
        test_upgrade_and_pause_successful();

        (uint8 v, bytes32 r, bytes32 s) = _signTransferAuthorization(al, bob, 1e18);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.transferWithAuthorization({
            from: al,
            to: bob,
            value: 1e18,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_receiveWithAuthorization_when_from_frozen_reverts() public {
        _upgradeAndFreeze(al);

        (uint8 v, bytes32 r, bytes32 s) = _signReceiveAuthorization(al, bob, 1e18);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.receiveWithAuthorization({
            from: al,
            to: bob,
            value: 1e18,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_receiveWithAuthorization_when_to_frozen_reverts() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.freeze(bob);

        (uint8 v, bytes32 r, bytes32 s) = _signReceiveAuthorization(al, bob, 1e18);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.receiveWithAuthorization({
            from: al,
            to: bob,
            value: 1e18,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_receiveWithAuthorization_when_paused_reverts() public {
        test_upgrade_and_pause_successful();

        (uint8 v, bytes32 r, bytes32 s) = _signReceiveAuthorization(al, bob, 1e18);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.receiveWithAuthorization({
            from: al,
            to: bob,
            value: 1e18,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_permit_succeeds_but_transferFrom_reverts_when_frozen() public {
        _upgradeAndFreeze(al);

        uint256 deadline = block.timestamp + 1 days;
        SigUtils.Permit memory _permit = SigUtils.Permit({
            owner: al,
            spender: bob,
            value: 1e18,
            nonce: frxusd.nonces(al),
            deadline: deadline
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alPrivateKey, sigUtils.getPermitTypedDataHash(_permit));

        // permit succeeds — approval is not gated by freeze
        vm.prank(bob);
        frxusd.permit({ owner: al, spender: bob, value: 1e18, deadline: deadline, v: v, r: r, s: s });

        assertEq({
            left: frxusd.allowance(al, bob),
            right: 1e18,
            err: "// THEN: permit should set allowance even when frozen"
        });

        // but transferFrom using that allowance reverts
        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.transferFrom(al, alice, 1e18);
    }

    function test_permit_succeeds_but_transferFrom_reverts_when_paused() public {
        test_upgrade_and_pause_successful();

        uint256 deadline = block.timestamp + 1 days;
        SigUtils.Permit memory _permit = SigUtils.Permit({
            owner: al,
            spender: bob,
            value: 1e18,
            nonce: frxusd.nonces(al),
            deadline: deadline
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alPrivateKey, sigUtils.getPermitTypedDataHash(_permit));

        // permit succeeds — approval is not gated by pause
        vm.prank(bob);
        frxusd.permit({ owner: al, spender: bob, value: 1e18, deadline: deadline, v: v, r: r, s: s });

        assertEq({
            left: frxusd.allowance(al, bob),
            right: 1e18,
            err: "// THEN: permit should set allowance even when paused"
        });

        // but transferFrom using that allowance reverts
        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.transferFrom(al, alice, 1e18);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>          Freezer Role Delegation Tests               <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_addFreezer_successful() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.addFreezer(carl);

        assertTrue(frxusd.isFreezer(carl), "// THEN: carl should be a freezer");
    }

    function test_addFreezer_reverts_if_already_freezer() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.addFreezer(carl);

        vm.prank(frxusd.owner());
        vm.expectRevert(bytes4(keccak256("AlreadyFreezer()")));
        frxusd.addFreezer(carl);
    }

    function test_only_owner_can_addFreezer() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.addFreezer(carl);
    }

    function test_removeFreezer_successful() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.addFreezer(carl);

        vm.prank(frxusd.owner());
        frxusd.removeFreezer(carl);

        assertFalse(frxusd.isFreezer(carl), "// THEN: carl should no longer be a freezer");
    }

    function test_removeFreezer_reverts_if_not_freezer() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        vm.expectRevert(bytes4(keccak256("NotFreezer()")));
        frxusd.removeFreezer(carl);
    }

    function test_only_owner_can_removeFreezer() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.removeFreezer(carl);
    }

    function test_freezer_can_freeze() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.addFreezer(carl);

        vm.prank(carl);
        frxusd.freeze(al);

        assertTrue(frxusd.isFrozen(al), "// THEN: al should be frozen by freezer");
    }

    function test_freezer_can_freezeMany() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.addFreezer(carl);

        targets.push(al);
        targets.push(bob);

        vm.prank(carl);
        frxusd.freezeMany(targets);

        assertTrue(frxusd.isFrozen(al), "// THEN: al should be frozen");
        assertTrue(frxusd.isFrozen(bob), "// THEN: bob should be frozen");
    }

    function test_non_freezer_cannot_freeze() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("NotFreezer()")));
        frxusd.freeze(al);
    }

    function test_non_freezer_cannot_freezeMany() public {
        _upgradeFrxUSD();

        targets.push(al);

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("NotFreezer()")));
        frxusd.freezeMany(targets);
    }

    function test_removed_freezer_cannot_freeze() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.addFreezer(carl);

        vm.prank(frxusd.owner());
        frxusd.removeFreezer(carl);

        vm.prank(carl);
        vm.expectRevert(bytes4(keccak256("NotFreezer()")));
        frxusd.freeze(al);
    }

    function test_freezer_cannot_thaw() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.addFreezer(carl);

        vm.prank(carl);
        frxusd.freeze(al);

        vm.prank(carl);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.thaw(al);
    }

    function test_freezer_cannot_thawMany() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.addFreezer(carl);

        targets.push(al);

        vm.prank(carl);
        frxusd.freezeMany(targets);

        vm.prank(carl);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.thawMany(targets);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>       Bridge Mint/Burn + Pause/Freeze Interaction    <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_bridge_mint_succeeds() public {
        _upgradeFrxUSD();

        uint256 balBefore = frxusd.balanceOf(alice);
        vm.prank(frxusd.BRIDGE());
        frxusd.mint(alice, 100e18);

        assertEq(frxusd.balanceOf(alice), balBefore + 100e18, "// THEN: bridge mint failed");
    }

    function test_bridge_burn_succeeds() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.BRIDGE());
        frxusd.burn(al, 50e18);

        assertEq(frxusd.balanceOf(al), 5000e18 - 50e18, "// THEN: bridge burn failed");
    }

    function test_bridge_mint_when_paused_reverts() public {
        test_upgrade_and_pause_successful();

        vm.prank(frxusd.BRIDGE());
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.mint(alice, 100e18);
    }

    function test_bridge_burn_when_paused_reverts() public {
        test_upgrade_and_pause_successful();

        vm.prank(frxusd.BRIDGE());
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.burn(al, 50e18);
    }

    function test_bridge_mint_to_frozen_address_reverts() public {
        _upgradeAndFreeze(al);

        vm.prank(frxusd.BRIDGE());
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.mint(al, 100e18);
    }

    function test_bridge_burn_from_frozen_address_reverts() public {
        _upgradeAndFreeze(al);

        vm.prank(frxusd.BRIDGE());
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.burn(al, 50e18);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>    ERC20Burnable burn/burnFrom + Pause/Freeze        <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_erc20_burn_succeeds() public {
        _upgradeFrxUSD();

        vm.prank(al);
        frxusd.burn(100e18);

        assertEq(frxusd.balanceOf(al), 5000e18 - 100e18, "// THEN: burn failed");
    }

    function test_erc20_burnFrom_succeeds() public {
        _upgradeFrxUSD();

        vm.prank(al);
        frxusd.approve(bob, 100e18);

        vm.prank(bob);
        frxusd.burnFrom(al, 100e18);

        assertEq(frxusd.balanceOf(al), 5000e18 - 100e18, "// THEN: burnFrom failed");
    }

    function test_erc20_burn_when_paused_reverts() public {
        test_upgrade_and_pause_successful();

        vm.prank(al);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.burn(100e18);
    }

    function test_erc20_burnFrom_when_paused_reverts() public {
        vm.prank(al);
        frxusd.approve(bob, 100e18);

        test_upgrade_and_pause_successful();

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.burnFrom(al, 100e18);
    }

    function test_erc20_burn_when_frozen_reverts() public {
        _upgradeAndFreeze(al);

        vm.prank(al);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.burn(100e18);
    }

    function test_erc20_burnFrom_when_from_frozen_reverts() public {
        vm.prank(al);
        frxusd.approve(bob, 100e18);

        _upgradeAndFreeze(al);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.burnFrom(al, 100e18);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>       Minter Functions + Pause/Freeze Interaction    <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_minter_mint_succeeds() public {
        _upgradeFrxUSD();

        address minter = address(0xAAAA);
        vm.prank(frxusd.owner());
        frxusd.addMinter(minter);

        vm.prank(minter);
        frxusd.minter_mint(alice, 100e18);

        assertEq(frxusd.balanceOf(alice), 100e18, "// THEN: minter mint failed");
    }

    function test_minter_burn_from_succeeds() public {
        _upgradeFrxUSD();

        address minter = address(0xAAAA);
        vm.prank(frxusd.owner());
        frxusd.addMinter(minter);

        vm.prank(al);
        frxusd.approve(minter, 100e18);

        vm.prank(minter);
        frxusd.minter_burn_from(al, 100e18);

        assertEq(frxusd.balanceOf(al), 5000e18 - 100e18, "// THEN: minter burn failed");
    }

    function test_minter_mint_when_paused_reverts() public {
        _upgradeFrxUSD();

        address minter = address(0xAAAA);
        vm.prank(frxusd.owner());
        frxusd.addMinter(minter);

        vm.prank(frxusd.owner());
        frxusd.pause();

        vm.prank(minter);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.minter_mint(alice, 100e18);
    }

    function test_minter_burn_from_when_paused_reverts() public {
        _upgradeFrxUSD();

        address minter = address(0xAAAA);
        vm.prank(frxusd.owner());
        frxusd.addMinter(minter);

        vm.prank(al);
        frxusd.approve(minter, 100e18);

        vm.prank(frxusd.owner());
        frxusd.pause();

        vm.prank(minter);
        vm.expectRevert(bytes4(keccak256("IsPaused()")));
        frxusd.minter_burn_from(al, 100e18);
    }

    function test_minter_mint_to_frozen_address_reverts() public {
        _upgradeAndFreeze(al);

        address minter = address(0xAAAA);
        vm.prank(frxusd.owner());
        frxusd.addMinter(minter);

        vm.prank(minter);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.minter_mint(al, 100e18);
    }

    function test_minter_burn_from_frozen_address_reverts() public {
        _upgradeFrxUSD();

        address minter = address(0xAAAA);
        vm.prank(frxusd.owner());
        frxusd.addMinter(minter);

        vm.prank(al);
        frxusd.approve(minter, 100e18);

        vm.prank(frxusd.owner());
        frxusd.freeze(al);

        vm.prank(minter);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.minter_burn_from(al, 100e18);
    }

    function test_addMinter_and_removeMinter() public {
        _upgradeFrxUSD();

        address minter = address(0xAAAA);
        vm.prank(frxusd.owner());
        frxusd.addMinter(minter);
        assertTrue(frxusd.minters(minter), "// THEN: minter not added");

        vm.prank(frxusd.owner());
        frxusd.removeMinter(minter);
        assertFalse(frxusd.minters(minter), "// THEN: minter not removed");
    }

    function test_minters_static_across_upgrade() public {
        // Snapshot all minters_array entries before upgrade
        address[] memory mintersPre = new address[](10);
        uint256 minterCount;
        for (uint256 i; i < 10; i++) {
            try frxusd.minters_array(i) returns (address m) {
                mintersPre[i] = m;
                minterCount = i + 1;
            } catch {
                break;
            }
        }

        // Snapshot minters mapping for each entry
        bool[] memory mintersMapPre = new bool[](minterCount);
        for (uint256 i; i < minterCount; i++) {
            if (mintersPre[i] != address(0)) {
                mintersMapPre[i] = frxusd.minters(mintersPre[i]);
            }
        }

        _upgradeFrxUSD();

        // Assert minters_array entries unchanged
        for (uint256 i; i < minterCount; i++) {
            assertEq(frxusd.minters_array(i), mintersPre[i], "// THEN: minters_array entry changed after upgrade");
        }

        // Assert minters mapping unchanged
        for (uint256 i; i < minterCount; i++) {
            if (mintersPre[i] != address(0)) {
                assertEq(
                    frxusd.minters(mintersPre[i]),
                    mintersMapPre[i],
                    "// THEN: minters mapping changed after upgrade"
                );
            }
        }
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>       Thaw / Unpause Round-Trip (Functional)         <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_freeze_then_thaw_transfer_succeeds() public {
        _upgradeAndFreeze(al);

        vm.prank(frxusd.owner());
        frxusd.thaw(al);
        assertFalse(frxusd.isFrozen(al), "// THEN: al should be thawed");

        vm.prank(al);
        frxusd.transfer(alice, 100e18);
        assertEq(frxusd.balanceOf(alice), 100e18, "// THEN: transfer after thaw failed");
    }

    function test_freezeMany_then_thawMany_transfer_succeeds() public {
        test_upgrade_and_freezeMany();

        vm.prank(frxusd.owner());
        frxusd.thawMany(targets);

        assertFalse(frxusd.isFrozen(al), "// THEN: al should be thawed");
        assertFalse(frxusd.isFrozen(carl), "// THEN: carl should be thawed");

        vm.prank(al);
        frxusd.transfer(alice, 10e18);
        assertEq(frxusd.balanceOf(alice), 10e18, "// THEN: transfer after thawMany failed");
    }

    function test_pause_then_unpause_transfer_succeeds() public {
        test_upgrade_and_pause_successful();

        vm.prank(frxusd.owner());
        frxusd.unpause();
        assertFalse(frxusd.isPaused(), "// THEN: frxusd should be unpaused");

        vm.prank(al);
        frxusd.transfer(alice, 100e18);
        assertEq(frxusd.balanceOf(alice), 100e18, "// THEN: transfer after unpause failed");
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>       EIP-3009 cancelAuthorization / authState       <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_cancelAuthorization_succeeds() public {
        _upgradeFrxUSD();

        SigUtils.CancelAuthorization memory cancelAuth = SigUtils.CancelAuthorization({
            authorizer: al,
            nonce: eip3009Nonce
        });
        bytes32 digest = sigUtils.getCancelAuthorizationTypedDataHash(cancelAuth);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alPrivateKey, digest);

        frxusd.cancelAuthorization(al, eip3009Nonce, v, r, s);

        assertTrue(frxusd.authorizationState(al, eip3009Nonce), "// THEN: authorization not canceled");
    }

    function test_transferWithAuthorization_after_cancel_reverts() public {
        test_cancelAuthorization_succeeds();

        (uint8 v, bytes32 r, bytes32 s) = _signTransferAuthorization(al, bob, 1e18);

        vm.prank(bob);
        vm.expectRevert();
        frxusd.transferWithAuthorization({
            from: al,
            to: bob,
            value: 1e18,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_authorizationState_default_false() public {
        _upgradeFrxUSD();

        assertFalse(frxusd.authorizationState(al, bytes32(uint256(999))), "// THEN: unused nonce should be false");
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>       Ownership Transfer (nominateNewOwner)          <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_nominateNewOwner_and_acceptOwnership() public {
        _upgradeFrxUSD();

        address currentOwner = frxusd.owner();
        address newOwner = address(0x4321);

        vm.prank(currentOwner);
        frxusd.nominateNewOwner(newOwner);
        assertEq(frxusd.nominatedOwner(), newOwner, "// THEN: nominated owner not set");

        vm.prank(newOwner);
        frxusd.acceptOwnership();
        assertEq(frxusd.owner(), newOwner, "// THEN: ownership not transferred");
        assertEq(frxusd.nominatedOwner(), address(0), "// THEN: nominated owner not cleared");
    }

    function test_only_owner_can_nominateNewOwner() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("OnlyOwner()")));
        frxusd.nominateNewOwner(badActor);
    }

    function test_only_nominated_can_acceptOwnership() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.nominateNewOwner(alice);

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("InvalidOwnershipAcceptance()")));
        frxusd.acceptOwnership();
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>    Frozen msg.sender (spender) in transferFrom       <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_transferFrom_frozen_spender_reverts() public {
        _upgradeFrxUSD();

        vm.prank(al);
        frxusd.approve(bob, 100e18);

        // freeze bob (the spender), al is NOT frozen
        vm.prank(frxusd.owner());
        frxusd.freeze(bob);

        // bob tries to transferFrom al to alice — should revert because bob (msg.sender) is frozen
        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.transferFrom(al, alice, 50e18);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>       supportsInterface                              <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_supportsInterface() public {
        _upgradeFrxUSD();

        // IERC165
        assertTrue(frxusd.supportsInterface(type(IERC165).interfaceId), "// THEN: should support IERC165");
        // IOptimismMintableERC20
        assertTrue(
            frxusd.supportsInterface(type(IOptimismMintableERC20).interfaceId),
            "// THEN: should support IOptimismMintableERC20"
        );
        // ILegacyMintableERC20
        assertTrue(
            frxusd.supportsInterface(type(ILegacyMintableERC20).interfaceId),
            "// THEN: should support ILegacyMintableERC20"
        );
        // unsupported interface
        assertFalse(frxusd.supportsInterface(bytes4(0xdeadbeef)), "// THEN: should not support random interface");
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>       setTimelock                                    <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_setTimelock_succeeds() public {
        _upgradeFrxUSD();

        address newTimelock = address(0x7777);
        vm.prank(frxusd.owner());
        frxusd.setTimelock(newTimelock);

        assertEq(frxusd.timelock_address(), newTimelock, "// THEN: timelock not updated");
    }

    function test_setTimelock_only_owner_or_timelock() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert("Not owner or timelock");
        frxusd.setTimelock(badActor);
    }

    function test_setTimelock_zero_address_reverts() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        vm.expectRevert("Zero address detected");
        frxusd.setTimelock(address(0));
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>            Helper functions to move state            <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function _upgradeAndFreeze(address toFreeze) public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.freeze(al);

        assertEq({ left: frxusd.isFrozen(toFreeze), right: true, err: "// THEN: users account is not frozen" });
    }

    function _signTransferAuthorization(
        address from,
        address to,
        uint256 value
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: from,
            to: to,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce
        });
        (v, r, s) = vm.sign(alPrivateKey, sigUtils.getTransferWithAuthorizationTypedDataHash(authorization));
    }

    function _signReceiveAuthorization(
        address from,
        address to,
        uint256 value
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: from,
            to: to,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: eip3009Nonce
        });
        (v, r, s) = vm.sign(alPrivateKey, sigUtils.getReceiveWithAuthorizationTypedDataHash(authorization));
    }

    function _upgradeFrxUSD() internal {
        address admin = address(
            uint160(uint256(vm.load(address(frxusd), bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1))))
        );
        IProxy proxyAdmin = IProxy(admin);
        console.log("The owner of frxUSD: ", proxyAdmin.owner());
        vm.prank(proxyAdmin.owner());
        console.log("The proxy Admin: ", address(proxyAdmin));
        console.log(address(frxusd), address(implV2));
        IProxy(address(proxyAdmin)).upgrade(address(frxusd), address(implV2));
        console.log("frxusd proxy: ", address(frxusd));
        console.log("implV2: ", address(implV2));
        address impl_post = address(
            uint160(uint256(vm.load(address(frxusd), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
        );
        assertEq({ left: address(implV2), right: impl_post });

        sigUtils = new SigUtils(frxusd.DOMAIN_SEPARATOR());
    }

    function test_case() public {
        _upgradeFrxUSD();
    }
}
