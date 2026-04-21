pragma solidity ^0.8.0;

import "frax-std/FraxTest.sol";
import "src/script/ethereum/sfrxUSD/DeploySfrxUSD.s.sol";
import { console } from "forge-std/console.sol";
import { SigUtils } from "src/test/utils/SigUtils.sol";

import { EIP3009Module } from "src/contracts/shared/core/modules/EIP3009Module.sol";
import { SignatureModule } from "src/contracts/shared/core/modules/SignatureModule.sol";

contract TestSfrxUSDSignatures is FraxTest {
    SfrxUSD public sfrxUsd;
    DeploySfrxUSD public deploySfrxUsd;
    SigUtils public sigUtils;

    uint256 BLOCK_NUM = 23_920_113;
    uint256 alPrivateKey = 0x42;
    address al = vm.addr(alPrivateKey);
    address bob = vm.addr(0xb0b);
    address owner = vm.addr(0x12345);
    uint256 value = 1e18;
    bytes32 nonce = bytes32(abi.encode(1)); // Example nonce, can be any value
    uint256 validAfter;
    uint256 validBefore;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.public.blastapi.io", BLOCK_NUM);

        deploySfrxUsd = new DeploySfrxUSD();
        deploySfrxUsd.setUp();
        deploySfrxUsd.runTest();

        sfrxUsd = SfrxUSD(SFRXUSD_PROXY);
        sigUtils = new SigUtils(sfrxUsd.DOMAIN_SEPARATOR());

        validAfter = block.timestamp - 1;
        validBefore = block.timestamp + 1 days;

        deal(address(sfrxUsd), al, 100e18);
        deal(address(sfrxUsd), bob, 100e18);

        vm.etch(al, hex"");
    }

    function test_DOMAIN_SEPARATOR_isCorrect() external {
        bytes32 domainSeparator = sfrxUsd.DOMAIN_SEPARATOR();
        bytes32 expectedDomainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(sfrxUsd.name())),
                keccak256("1"),
                block.chainid,
                address(sfrxUsd)
            )
        );
        assertEq(domainSeparator, expectedDomainSeparator, "DOMAIN_SEPARATOR is incorrect");
    }

    function test_Permit_succeeds() external {
        /// al permits to bob
        uint256 permitAllowanceBefore = sfrxUsd.allowance(al, bob);
        assertEq(permitAllowanceBefore, 0, "Permit allowance should be 0 beforehand");

        uint256 deadline = block.timestamp + 1 days;
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: al,
            spender: bob,
            value: 1e18,
            nonce: sfrxUsd.nonces(al),
            deadline: deadline
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alPrivateKey, sigUtils.getPermitTypedDataHash(permit));

        vm.prank(bob);
        sfrxUsd.permit({
            owner: permit.owner,
            spender: permit.spender,
            value: permit.value,
            deadline: permit.deadline,
            v: v,
            r: r,
            s: s
        });

        uint256 permitAllowanceAfter = sfrxUsd.allowance(al, bob);
        assertEq(permitAllowanceAfter, 1e18, "Permit allowance should now be 1e18");

        permit = SigUtils.Permit({
            owner: al,
            spender: bob,
            value: 2e18,
            nonce: sfrxUsd.nonces(al),
            deadline: deadline
        });
        (v, r, s) = vm.sign(alPrivateKey, sigUtils.getPermitTypedDataHash(permit));
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(bob);
        sfrxUsd.permit({
            owner: permit.owner,
            spender: permit.spender,
            value: permit.value,
            deadline: permit.deadline,
            signature: signature
        });
        permitAllowanceAfter = sfrxUsd.allowance(al, bob);
        assertEq(permitAllowanceAfter, 2e18, "Permit allowance should now be 2e18");
    }

    function test_TransferWithAuthorization_succeeds() public {
        uint256 balanceBefore = sfrxUsd.balanceOf(bob);
        assertEq(balanceBefore, 100e18, "Bob's balance should be 100e18 before transfer");

        // al authorized bob to transfer 1e18 from al to bob
        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alPrivateKey,
            sigUtils.getTransferWithAuthorizationTypedDataHash(authorization)
        );

        vm.prank(bob);
        sfrxUsd.transferWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            v: v,
            r: r,
            s: s
        });

        uint256 balanceAfter = sfrxUsd.balanceOf(bob);
        assertEq(balanceAfter, balanceBefore + value, "Bob's balance should now be 101e18");
        assertTrue(sfrxUsd.authorizationState(al, nonce), "Authorization should be marked as used");
    }

    function test_ReceiveWithAuthorization_succeeds() public {
        uint256 balanceBefore = sfrxUsd.balanceOf(bob);
        assertEq(balanceBefore, 100e18, "Bob's balance should be 100e18 before transfer");

        // al authorized bob to transfer 1e18 from al to bob
        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alPrivateKey,
            sigUtils.getReceiveWithAuthorizationTypedDataHash(authorization)
        );

        vm.prank(bob);
        sfrxUsd.receiveWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            v: v,
            r: r,
            s: s
        });

        uint256 balanceAfter = sfrxUsd.balanceOf(bob);
        assertEq(balanceAfter, balanceBefore + value, "Bob's balance should now be 101e18");
        assertTrue(sfrxUsd.authorizationState(al, nonce), "Authorization should be marked as used");
    }

    function test_CancelAuthorization_succeeds() public {
        // al authorizes bob to transfer 1e18 from al to bob
        SigUtils.CancelAuthorization memory cancelAuthorization = SigUtils.CancelAuthorization({
            authorizer: al,
            nonce: nonce
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alPrivateKey,
            sigUtils.getCancelAuthorizationTypedDataHash(cancelAuthorization)
        );

        // al cancels the authorization
        vm.prank(al);
        sfrxUsd.cancelAuthorization({ authorizer: al, nonce: nonce, v: v, r: r, s: s });

        assertTrue(sfrxUsd.authorizationState(al, nonce), "Authorization should be marked as used");

        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce
        });
        (v, r, s) = vm.sign(alPrivateKey, sigUtils.getTransferWithAuthorizationTypedDataHash(authorization));

        // try to transfer with authorization should fail
        vm.expectRevert(EIP3009Module.UsedOrCanceledAuthorization.selector);
        vm.prank(bob);
        sfrxUsd.transferWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_CancelAuthorization_UsedOrCanceledAuthorization_reverts() external {
        // Successful auth with nonce 1
        test_CancelAuthorization_succeeds();

        SigUtils.CancelAuthorization memory cancelAuthorization = SigUtils.CancelAuthorization({
            authorizer: al,
            nonce: nonce
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alPrivateKey,
            sigUtils.getCancelAuthorizationTypedDataHash(cancelAuthorization)
        );

        // al cancels the authorization
        vm.prank(al);
        vm.expectRevert(EIP3009Module.UsedOrCanceledAuthorization.selector);
        sfrxUsd.cancelAuthorization({ authorizer: al, nonce: nonce, v: v, r: r, s: s });
    }

    function test_TransferWithAuthorization_UsedOrCanceledAuthorization_reverts() external {
        // Successful auth with nonce 1
        test_TransferWithAuthorization_succeeds();

        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alPrivateKey,
            sigUtils.getTransferWithAuthorizationTypedDataHash(authorization)
        );

        // Try to transfer with authorization should fail
        vm.expectRevert(EIP3009Module.UsedOrCanceledAuthorization.selector);
        vm.prank(bob);
        sfrxUsd.transferWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_ReceiveWithAuthorization_UsedOrCanceledAuthorization_reverts() external {
        // Successful auth with nonce 1
        test_ReceiveWithAuthorization_succeeds();

        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alPrivateKey,
            sigUtils.getReceiveWithAuthorizationTypedDataHash(authorization)
        );

        // Try to receive with authorization should fail
        vm.expectRevert(EIP3009Module.UsedOrCanceledAuthorization.selector);
        vm.prank(bob);
        sfrxUsd.receiveWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_TransferWithAuthorization_InvalidAuthorization_reverts() external {
        // Try to transfer with authorization should fail
        vm.expectRevert(EIP3009Module.InvalidAuthorization.selector);
        vm.prank(bob);
        sfrxUsd.transferWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: block.timestamp,
            validBefore: validBefore,
            nonce: nonce,
            v: uint8(0),
            r: bytes32(0),
            s: bytes32(0)
        });
    }

    function test_ReceiveWithAuthorization_InvalidAuthorization_reverts() external {
        // Try to transfer with authorization should fail
        vm.expectRevert(EIP3009Module.InvalidAuthorization.selector);
        vm.prank(bob);
        sfrxUsd.receiveWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: block.timestamp,
            validBefore: validBefore,
            nonce: nonce,
            v: uint8(0),
            r: bytes32(0),
            s: bytes32(0)
        });
    }

    function test_TransferWithAuthorization_ExpiredAuthorization_reverts() external {
        // Try to transfer with authorization should fail
        vm.expectRevert(EIP3009Module.ExpiredAuthorization.selector);
        vm.prank(bob);
        sfrxUsd.transferWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: block.timestamp,
            nonce: nonce,
            v: uint8(0),
            r: bytes32(0),
            s: bytes32(0)
        });
    }

    function test_ReceiveWithAuthorization_ExpiredAuthorization_reverts() external {
        // Try to transfer with authorization should fail
        vm.expectRevert(EIP3009Module.ExpiredAuthorization.selector);
        vm.prank(bob);
        sfrxUsd.receiveWithAuthorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: block.timestamp,
            nonce: nonce,
            v: uint8(0),
            r: bytes32(0),
            s: bytes32(0)
        });
    }

    function test_ReceiveWithAuthorization_InvalidPayee_reverts() external {
        vm.expectRevert(abi.encodeWithSelector(EIP3009Module.InvalidPayee.selector, bob, owner));
        vm.prank(bob);
        sfrxUsd.receiveWithAuthorization({
            from: al,
            to: owner, // Invalid payee
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            v: uint8(0),
            r: bytes32(0),
            s: bytes32(0)
        });
    }

    function test_TransferWithAuthorization_InvalidSignature_reverts() external {
        // al authorized bob to transfer 1e18 from al to bob
        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: al,
            to: bob,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alPrivateKey,
            sigUtils.getTransferWithAuthorizationTypedDataHash(authorization)
        );

        // bob tries to transfer from al to owner, which is not conformed to the signature
        vm.prank(bob);
        vm.expectRevert(SignatureModule.InvalidSignature.selector);
        sfrxUsd.transferWithAuthorization({
            from: al,
            to: owner, // note: this is causing the revert
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            v: v,
            r: r,
            s: s
        });
    }

    function test_ReceiveWithAuthorization_InvalidSignature_reverts() external {
        // al authorized owner to transfer 1e18 from al to bob
        SigUtils.Authorization memory authorization = SigUtils.Authorization({
            from: al,
            to: owner,
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alPrivateKey,
            sigUtils.getReceiveWithAuthorizationTypedDataHash(authorization)
        );

        // bob tries to receive the tokens, which is not conformed to the signature
        vm.prank(bob);
        vm.expectRevert(SignatureModule.InvalidSignature.selector);
        sfrxUsd.receiveWithAuthorization({
            from: al,
            to: bob, // note: this is causing the revert
            value: value,
            validAfter: validAfter,
            validBefore: validBefore,
            nonce: nonce,
            v: v,
            r: r,
            s: s
        });
    }
}
