// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/FraxTest.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { FrxUSD } from "src/contracts/ethereum/frxUSD/FrxUSD.sol";
import { IFrxUSD } from "src/contracts/ethereum/frxUSD/IFrxUSD.sol";
import { IProxy } from "src/test/helpers/IProxy.sol";
import { SigUtils } from "src/test/utils/SigUtils.sol";
import { EIP3009Module } from "src/contracts/shared/core/modules/EIP3009Module.sol";
import "src/Constants.sol" as Constants;

contract FrxUSD_Mainnet_Compliance is FraxTest {
    IFrxUSD public constant frxusd = IFrxUSD(0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29);
    IFrxUSD public implV2;
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
        vm.createSelectFork(vm.envString("MAINNET_URL"));

        al = vm.addr(alPrivateKey);

        /// @notice needed to register under coverage report
        // implV2 = IFrxUSD(deployFrxUsdImplementationEth());
        // implV2 = IFrxUSD(address(new FrxUSD(address(Constants.Mainnet.COMPTROLLER_MULTISIG), "Frax USD", "frxUSD")));

        // implV2 = IFrxUSD(address(new FrxUSD()));
        implV2 = IFrxUSD(0x0000000048D2c8baf31742f6765383278BAda4d5);

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

        // check that all slots less slot #12 match
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
            if (i != 13) {
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
        frxusd.burn(al, 50e18);

        assertEq({
            left: frxusd.balanceOf(al),
            right: 5000e18 - 50e18,
            err: "// THEN: al's balance not decremented correctly"
        });

        vm.prank(frxusd.owner());
        frxusd.burn(al, 0);
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
        frxusd.burn(al, 50e18);

        assertEq({
            left: frxusd.balanceOf(al),
            right: 5000e18 - 50e18,
            err: "// THEN: al's balance not decremented correctly"
        });

        vm.prank(frxusd.owner());
        frxusd.burn(al, 0);
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
        frxusd.burn(al, 50e18);

        assertEq({
            left: frxusd.balanceOf(al),
            right: 5000e18 - 50e18,
            err: "// THEN: al's balance not decremented correctly"
        });

        vm.prank(frxusd.owner());
        frxusd.burn(al, 0);
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

    function test_pendingOwner_static() public {
        address pendingPre = frxusd.pendingOwner();
        console.log("Pending Owner Pre: ", pendingPre);
        _upgradeFrxUSD();
        address pendingPost = frxusd.pendingOwner();
        console.log("Pending Owner Post: ", pendingPost);
        assertEq(pendingPost, pendingPre, "// THEN: Pending owner changed during upgrade");
    }

    function test_version_change() public {
        string memory versionPre = frxusd.version();
        _upgradeFrxUSD();
        string memory versionPost = frxusd.version();
        console.log("Version Post: ", versionPost);
        assertEq("3.0.0", versionPost);
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
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        frxusd.pause();
    }

    function test_only_owner_can_unpause() public {
        test_upgrade_and_pause_successful();

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        frxusd.unpause();
    }

    function test_only_owner_can_freeze() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("NotFreezer()")));
        frxusd.freeze(bob);
    }

    function test_only_owner_can_thaw() public {
        test_upgrade_and_freeze_successful();

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        frxusd.thaw(al);
    }

    function test_only_owner_can_freezeMany() public {
        _upgradeFrxUSD();

        targets.push(bob);
        targets.push(carl);

        vm.prank(badActor);
        vm.expectRevert(bytes4(keccak256("NotFreezer()")));
        frxusd.freezeMany(targets);
    }

    function test_only_owner_can_thawMany() public {
        test_upgrade_and_freezeMany();

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        /// @notice targets array populated w/n `test_upgrade_and_freezeMany`
        frxusd.thawMany(targets);
    }

    function test_only_owner_can_burn() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        frxusd.burn(al, 0);
    }

    function test_only_owner_can_burnMany() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(carl);
        amounts.push(0);
        amounts.push(0);

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
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
        FrxUSD(address(frxusd)).transferWithAuthorization({
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
        FrxUSD(address(frxusd)).transferWithAuthorization({
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
        FrxUSD(address(frxusd)).transferWithAuthorization({
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
        FrxUSD(address(frxusd)).receiveWithAuthorization({
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
        FrxUSD(address(frxusd)).receiveWithAuthorization({
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
        FrxUSD(address(frxusd)).receiveWithAuthorization({
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
            nonce: FrxUSD(address(frxusd)).nonces(al),
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
            nonce: FrxUSD(address(frxusd)).nonces(al),
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
        FrxUSD(address(frxusd)).addFreezer(carl);

        assertTrue(FrxUSD(address(frxusd)).isFreezer(carl), "// THEN: carl should be a freezer");
    }

    function test_addFreezer_reverts_if_already_freezer() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addFreezer(carl);

        vm.prank(frxusd.owner());
        vm.expectRevert(bytes4(keccak256("AlreadyFreezer()")));
        FrxUSD(address(frxusd)).addFreezer(carl);
    }

    function test_only_owner_can_addFreezer() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        FrxUSD(address(frxusd)).addFreezer(carl);
    }

    function test_removeFreezer_successful() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addFreezer(carl);

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).removeFreezer(carl);

        assertFalse(FrxUSD(address(frxusd)).isFreezer(carl), "// THEN: carl should no longer be a freezer");
    }

    function test_removeFreezer_reverts_if_not_freezer() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        vm.expectRevert(bytes4(keccak256("NotFreezer()")));
        FrxUSD(address(frxusd)).removeFreezer(carl);
    }

    function test_only_owner_can_removeFreezer() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        FrxUSD(address(frxusd)).removeFreezer(carl);
    }

    function test_freezer_can_freeze() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addFreezer(carl);

        vm.prank(carl);
        frxusd.freeze(al);

        assertTrue(frxusd.isFrozen(al), "// THEN: al should be frozen by freezer");
    }

    function test_freezer_can_freezeMany() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addFreezer(carl);

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
        FrxUSD(address(frxusd)).addFreezer(carl);

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).removeFreezer(carl);

        vm.prank(carl);
        vm.expectRevert(bytes4(keccak256("NotFreezer()")));
        frxusd.freeze(al);
    }

    function test_freezer_cannot_thaw() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addFreezer(carl);

        vm.prank(carl);
        frxusd.freeze(al);

        vm.prank(carl);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", carl));
        frxusd.thaw(al);
    }

    function test_freezer_cannot_thawMany() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addFreezer(carl);

        targets.push(al);

        vm.prank(carl);
        frxusd.freezeMany(targets);

        vm.prank(carl);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", carl));
        frxusd.thawMany(targets);
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
        console.log("The proxy Admin: ", address(proxyAdmin));
        vm.prank(proxyAdmin.owner());
        IProxy(address(proxyAdmin)).upgradeAndCall(address(frxusd), address(implV2), hex"");
        console.log("frxUSD Proxy Address: ", address(frxusd));
        console.log("Implementation Address: ", address(implV2));
        address impl_post = address(
            uint160(uint256(vm.load(address(frxusd), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
        );
        console.log("THe new implementation is: ", impl_post);
        assertEq({ left: address(implV2), right: impl_post });

        sigUtils = new SigUtils(frxusd.DOMAIN_SEPARATOR());
    }

    function test_case() public {
        _upgradeFrxUSD();
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>        Transfer To / Spender Frozen Tests          <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_transfer_to_frozen_reverts() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        frxusd.freeze(alice);

        vm.prank(al);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.transfer(alice, 100e18);
    }

    function test_transferFrom_when_spender_frozen_reverts() public {
        vm.prank(al);
        frxusd.approve(bob, 100e18);

        _upgradeFrxUSD();

        // freeze bob (the spender / msg.sender), not al (the from)
        vm.prank(frxusd.owner());
        frxusd.freeze(bob);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("IsFrozen()")));
        frxusd.transferFrom(al, alice, 100e18);
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>        Thaw / Unpause Restoration Tests            <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_thaw_restores_transfer() public {
        _upgradeAndFreeze(al);

        vm.prank(frxusd.owner());
        frxusd.thaw(al);

        assertEq({ left: frxusd.isFrozen(al), right: false, err: "// THEN: al should no longer be frozen" });

        uint256 balBefore = frxusd.balanceOf(alice);
        vm.prank(al);
        frxusd.transfer(alice, 100e18);
        assertEq({
            left: frxusd.balanceOf(alice) - balBefore,
            right: 100e18,
            err: "// THEN: transfer should succeed after thaw"
        });
    }

    function test_thawMany_restores_transfers() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(carl);

        vm.prank(frxusd.owner());
        frxusd.freezeMany(targets);

        vm.prank(frxusd.owner());
        frxusd.thawMany(targets);

        assertEq({ left: frxusd.isFrozen(al), right: false, err: "// THEN: al should no longer be frozen" });
        assertEq({ left: frxusd.isFrozen(carl), right: false, err: "// THEN: carl should no longer be frozen" });

        vm.prank(al);
        frxusd.transfer(alice, 100e18);

        vm.prank(carl);
        frxusd.transfer(alice, 10e18);
    }

    function test_unpause_restores_transfer() public {
        test_upgrade_and_pause_successful();

        vm.prank(frxusd.owner());
        frxusd.unpause();

        assertEq({ left: frxusd.isPaused(), right: false, err: "// THEN: frxusd should not be paused" });

        uint256 balBefore = frxusd.balanceOf(alice);
        vm.prank(al);
        frxusd.transfer(alice, 100e18);
        assertEq({
            left: frxusd.balanceOf(alice) - balBefore,
            right: 100e18,
            err: "// THEN: transfer should succeed after unpause"
        });
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>            Partial burnMany Test                   <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_burnMany_with_specific_amounts() public {
        _upgradeFrxUSD();

        targets.push(al);
        targets.push(bob);
        targets.push(carl);

        amounts.push(1000e18);
        amounts.push(5e18);
        amounts.push(69e18);

        vm.prank(frxusd.owner());
        frxusd.burnMany(targets, amounts);

        assertEq({
            left: frxusd.balanceOf(al),
            right: 5000e18 - 1000e18,
            err: "// THEN: al's balance not decremented correctly"
        });
        assertEq({
            left: frxusd.balanceOf(bob),
            right: 15e18 - 5e18,
            err: "// THEN: bob's balance not decremented correctly"
        });
        assertEq({ left: frxusd.balanceOf(carl), right: 0, err: "// THEN: carl's balance not decremented correctly" });
    }

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>          cancelAuthorization Tests                 <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_cancelAuthorization_blocks_transferWithAuthorization() public {
        _upgradeFrxUSD();

        (uint8 vCancel, bytes32 rCancel, bytes32 sCancel) = _signCancelAuthorization(al, eip3009Nonce);
        FrxUSD(address(frxusd)).cancelAuthorization(al, eip3009Nonce, vCancel, rCancel, sCancel);

        assertTrue(
            FrxUSD(address(frxusd)).authorizationState(al, eip3009Nonce),
            "// THEN: nonce should be marked used"
        );

        (uint8 v, bytes32 r, bytes32 s) = _signTransferAuthorization(al, bob, 1e18);

        vm.prank(bob);
        vm.expectRevert(bytes4(keccak256("UsedOrCanceledAuthorization()")));
        FrxUSD(address(frxusd)).transferWithAuthorization({
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

    /*
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    <*>                  Minter Tests                      <*>
    <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
    */

    function test_addMinter_successful() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addMinter(carl);

        assertTrue(FrxUSD(address(frxusd)).minters(carl), "// THEN: carl should be a minter");
    }

    function test_only_owner_can_addMinter() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        FrxUSD(address(frxusd)).addMinter(carl);
    }

    function test_removeMinter_successful() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addMinter(carl);

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).removeMinter(carl);

        assertFalse(FrxUSD(address(frxusd)).minters(carl), "// THEN: carl should no longer be a minter");
    }

    function test_only_owner_can_removeMinter() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addMinter(carl);

        vm.prank(badActor);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
        FrxUSD(address(frxusd)).removeMinter(carl);
    }

    function test_minter_can_mint() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addMinter(carl);

        uint256 supplyBefore = frxusd.totalSupply();

        vm.prank(carl);
        FrxUSD(address(frxusd)).minter_mint(alice, 1000e18);

        assertEq({ left: frxusd.balanceOf(alice), right: 1000e18, err: "// THEN: alice balance not as expected" });
        assertEq({
            left: frxusd.totalSupply(),
            right: supplyBefore + 1000e18,
            err: "// THEN: total supply not as expected"
        });
    }

    function test_non_minter_cannot_mint() public {
        _upgradeFrxUSD();

        vm.prank(badActor);
        vm.expectRevert("Only minters");
        FrxUSD(address(frxusd)).minter_mint(alice, 1000e18);
    }

    function test_minter_can_burn_from() public {
        _upgradeFrxUSD();

        vm.prank(frxusd.owner());
        FrxUSD(address(frxusd)).addMinter(carl);

        vm.prank(al);
        frxusd.approve(carl, 500e18);

        uint256 balBefore = frxusd.balanceOf(al);

        vm.prank(carl);
        FrxUSD(address(frxusd)).minter_burn_from(al, 500e18);

        assertEq({
            left: frxusd.balanceOf(al),
            right: balBefore - 500e18,
            err: "// THEN: al's balance not decremented correctly"
        });
    }

    function test_non_minter_cannot_burn_from() public {
        _upgradeFrxUSD();

        vm.prank(al);
        frxusd.approve(badActor, 500e18);

        vm.prank(badActor);
        vm.expectRevert("Only minters");
        FrxUSD(address(frxusd)).minter_burn_from(al, 500e18);
    }

    function _signCancelAuthorization(
        address authorizer,
        bytes32 nonce
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        SigUtils.CancelAuthorization memory cancelAuth = SigUtils.CancelAuthorization({
            authorizer: authorizer,
            nonce: nonce
        });
        (v, r, s) = vm.sign(alPrivateKey, sigUtils.getCancelAuthorizationTypedDataHash(cancelAuth));
    }
}
