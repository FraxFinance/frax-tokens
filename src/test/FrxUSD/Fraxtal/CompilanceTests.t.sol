// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// import "frax-std/FraxTest.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import { FrxUSD } from "src/contracts/ethereum/frxUSD/FrxUSD.sol";
// import { IFrxUSD } from "src/contracts/ethereum/frxUSD/IFrxUSD.sol";
// import { IProxy } from "src/test/helpers/IProxy.sol";
// import "src/Constants.sol" as Constants;

// contract FrxUSD_Mainnet_Compiance is FraxTest {
//   IFrxUSD public constant frxusd = IFrxUSD(0xCAcd6fd266aF91b8AeD52aCCc382b4e165586E29);
//   IFrxUSD public implV2;

//   address al = address(0xa1);
//   address bob = address(0xb0b);
//   address carl = address(0xca71);
//   address alice = address(0xa11ce);
//   address badActor = address(0xbadbeef);

//   address[] targets;
//   uint256[] amounts;

//   bytes32[] frxusdStorageLayoutInitial;

//   function setUp() public virtual {
//     vm.createSelectFork(vm.envString("MAINNET_URL"));

//     /// @notice needed to register under coverage report
//     // implV2 = IFrxUSD(deployFrxUsdImplementationEth());
//     implV2 = IFrxUSD(address(new FrxUSD(
//         address(Constants.Mainnet.COMPTROLLER_MULTISIG),
//         "Frax USD",
//         "frxUSD"
//     )));
//     // implV2 = FrxUSD(0x000000003C7F01B12c2D2097Cf7b95358E7E5812);

//     deal(address(frxusd), al, 5000e18);
//     deal(address(frxusd), bob, 15e18);
//     deal(address(frxusd), carl, 69e18);
//   }

//   function test_assert_balances_remain_constant() public {
//     _upgradeFrxUSD();
//     assertEq({ left: frxusd.balanceOf(al), right: 5000e18, err: "// THEN: balance not constant" });
//     assertEq({ left: frxusd.balanceOf(bob), right: 15e18, err: "// THEN: balance not constant" });
//     assertEq({ left: frxusd.balanceOf(carl), right: 69e18, err: "// THEN: balance not constant" });
//     assertEq({ left: frxusd.balanceOf(alice), right: 0, err: "// THEN: balance not constant" });
//   }

//   function test_cannot_reInit_post_upgrade() public {
//     _upgradeFrxUSD();
//     vm.expectRevert(bytes("Already initialized"));
//     frxusd.initialize(badActor, "Bad", "Bad");
//   }

//   function test_storage_layout_remains_constant() public {
//     for (uint i; i < 20; i++) {
//       bytes32 slotVal = vm.load(address(frxusd), bytes32(uint(i)));
//       frxusdStorageLayoutInitial.push(slotVal);
//     }
//     _upgradeFrxUSD();

//     // check that all slots less slot #12 match
//     for (uint i; i < 20; i++) {
//       bytes32 slotVal = vm.load(address(frxusd), bytes32(uint(i)));
//       assertEq({ left: frxusdStorageLayoutInitial[i], right: slotVal, err: "// THEN: slot value not expected" });
//     }
//   }

//   function test_storage_layout_change_when_paused() public {
//     for (uint i; i < 20; i++) {
//       bytes32 slotVal = vm.load(address(frxusd), bytes32(uint(i)));
//       frxusdStorageLayoutInitial.push(slotVal);
//     }
//     test_upgrade_and_pause_successful();

//     // check that all slots less slot #12 match
//     for (uint i; i < 20; i++) {
//       bytes32 slotVal = vm.load(address(frxusd), bytes32(uint(i)));
//       if (i != 13) {
//         assertEq({ left: frxusdStorageLayoutInitial[i], right: slotVal, err: "// THEN: slot value not expected" });
//       } else {
//         assertEq({ left: bytes32(uint(1)), right: slotVal, err: "// THEN: slot value not expected" });
//       }
//     }
//   }

//   function test_transfer() public {
//     _upgradeFrxUSD();

//     uint balAliceBefore = frxusd.balanceOf(alice);
//     uint balAlBefore = frxusd.balanceOf(al);

//     vm.prank(al);
//     frxusd.transfer(alice, 100e18);

//     uint balAliceAfter = frxusd.balanceOf(alice);
//     uint balAlAfter = frxusd.balanceOf(al);

//     assertEq({ right: balAlBefore - balAlAfter, left: 100e18, err: "// THEN: balance change of al not expected" });

//     assertEq({
//       right: balAliceAfter - balAliceBefore,
//       left: 100e18,
//       err: "// THEN: balance change of alice not expected"
//     });
//   }

//   function test_transfer_too_much() public {
//     _upgradeFrxUSD();

//     uint balAliceBefore = frxusd.balanceOf(alice);
//     uint balAlBefore = frxusd.balanceOf(al);

//     vm.prank(al);
//     vm.expectRevert(
//       abi.encodeWithSignature(
//         "ERC20InsufficientBalance(address,uint256,uint256)",
//         address(al),
//         uint(5000e18),
//         uint(100_000e18)
//       )
//     );
//     frxusd.transfer(alice, 100_000e18);

//     uint balAliceAfter = frxusd.balanceOf(alice);
//     uint balAlAfter = frxusd.balanceOf(al);

//     assertEq({ right: balAlBefore - balAlAfter, left: 0, err: "// THEN: balance change of al not expected" });

//     assertEq({ right: balAliceAfter - balAliceBefore, left: 0, err: "// THEN: balance change of alice not expected" });
//   }

//   function test_transfer_when_paused_reverts() public {
//     test_upgrade_and_pause_successful();

//     vm.prank(al);
//     vm.expectRevert(bytes4(keccak256("IsPaused()")));
//     frxusd.transfer(alice, 1e18);
//   }

//   function test_transferFrom_when_paused_revert() public {
//     vm.prank(al);
//     frxusd.approve(bob, 10e18);

//     test_upgrade_and_pause_successful();

//     vm.prank(bob);
//     vm.expectRevert(bytes4(keccak256("IsPaused()")));
//     frxusd.transferFrom(al, alice, 1e18);
//   }

//   function test_upgrade_and_pause_successful() public {
//     _upgradeFrxUSD();
//     vm.prank(frxusd.owner());
//     frxusd.pause();
//     assertEq({ left: frxusd.isPaused(), right: true, err: "// THEN: frxusd is not paused" });
//   }

//   function test_upgrade_and_freeze_successful() public {
//     _upgradeAndFreeze(al);
//   }

//   function test_upgrade_and_freeze_transfer_Reverts() public {
//     _upgradeAndFreeze(al);

//     vm.prank(al);
//     vm.expectRevert(bytes4(keccak256("IsFrozen()")));
//     frxusd.transfer(alice, 100e18);
//   }

//   function test_upgrade_and_freezeMany() public {
//     _upgradeFrxUSD();

//     targets.push(al);
//     targets.push(carl);

//     vm.prank(frxusd.owner());
//     frxusd.freezeMany(targets);

//     assertEq({ left: frxusd.isFrozen(al), right: true, err: "// THEN: al was not frozen" });
//     assertEq({ left: frxusd.isFrozen(carl), right: true, err: "// THEN: carl was not frozen" });
//   }

//   function test_upgrade_and_freeze_transferFrom_Reverts() public {
//     vm.prank(al);
//     frxusd.approve(bob, 100e18);

//     _upgradeAndFreeze(al);

//     vm.expectRevert(bytes4(keccak256("IsFrozen()")));
//     vm.prank(bob);
//     frxusd.transferFrom(al, alice, 100e18);
//   }

//   function test_can_burn_tokens() public {
//     _upgradeFrxUSD();

//     vm.prank(frxusd.owner());
//     frxusd.burn(al, 50e18);

//     assertEq({
//       left: frxusd.balanceOf(al),
//       right: 5000e18 - 50e18,
//       err: "// THEN: al's balance not decremented correctly"
//     });

//     vm.prank(frxusd.owner());
//     frxusd.burn(al, 0);
//     assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
//   }

//   function test_can_burnMany_tokens() public {
//     _upgradeFrxUSD();

//     targets.push(al);
//     targets.push(bob);
//     targets.push(carl);

//     amounts.push(0);
//     amounts.push(0);
//     amounts.push(0);

//     vm.prank(frxusd.owner());
//     frxusd.burnMany(targets, amounts);

//     assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
//     assertEq({ left: frxusd.balanceOf(carl), right: 0, err: "// THEN: carl's balance not decremented correctly" });
//     assertEq({ left: frxusd.balanceOf(bob), right: 0, err: "// THEN: bob's balance not decremented correctly" });
//   }

//   function test_can_burn_tokens_when_frozen() public {
//     _upgradeFrxUSD();

//     vm.prank(frxusd.owner());
//     frxusd.freeze(al);

//     vm.prank(frxusd.owner());
//     frxusd.burn(al, 50e18);

//     assertEq({
//       left: frxusd.balanceOf(al),
//       right: 5000e18 - 50e18,
//       err: "// THEN: al's balance not decremented correctly"
//     });

//     vm.prank(frxusd.owner());
//     frxusd.burn(al, 0);
//     assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
//   }

//   function test_can_burnMany_tokens_when_frozen() public {
//     _upgradeFrxUSD();

//     targets.push(al);
//     targets.push(bob);
//     targets.push(carl);

//     amounts.push(0);
//     amounts.push(0);
//     amounts.push(0);

//     vm.prank(frxusd.owner());
//     frxusd.freezeMany(targets);

//     vm.prank(frxusd.owner());
//     frxusd.burnMany(targets, amounts);

//     assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
//     assertEq({ left: frxusd.balanceOf(carl), right: 0, err: "// THEN: carl's balance not decremented correctly" });
//     assertEq({ left: frxusd.balanceOf(bob), right: 0, err: "// THEN: bob's balance not decremented correctly" });
//   }

//   function test_can_burn_tokens_when_paused() public {
//     _upgradeFrxUSD();

//     vm.prank(frxusd.owner());
//     frxusd.pause();

//     vm.prank(frxusd.owner());
//     frxusd.burn(al, 50e18);

//     assertEq({
//       left: frxusd.balanceOf(al),
//       right: 5000e18 - 50e18,
//       err: "// THEN: al's balance not decremented correctly"
//     });

//     vm.prank(frxusd.owner());
//     frxusd.burn(al, 0);
//     assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
//   }

//   function test_can_burnMany_tokens_when_paused() public {
//     _upgradeFrxUSD();

//     targets.push(al);
//     targets.push(bob);
//     targets.push(carl);

//     amounts.push(0);
//     amounts.push(0);
//     amounts.push(0);

//     vm.prank(frxusd.owner());
//     frxusd.pause();

//     vm.prank(frxusd.owner());
//     frxusd.burnMany(targets, amounts);

//     assertEq({ left: frxusd.balanceOf(al), right: 0, err: "// THEN: al's balance not decremented correctly" });
//     assertEq({ left: frxusd.balanceOf(carl), right: 0, err: "// THEN: carl's balance not decremented correctly" });
//     assertEq({ left: frxusd.balanceOf(bob), right: 0, err: "// THEN: bob's balance not decremented correctly" });
//   }

//   /*
//   <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
//   <*>            Pre And Post State Assertions          <*>
//   <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
//   */
//   function test_allowances_static() public {
//     vm.prank(al);
//     frxusd.approve(bob, 500e18);

//     uint allowancePre = frxusd.allowance(al, bob);
//     _upgradeFrxUSD();
//     uint allowancePost = frxusd.allowance(al, bob);
//     assertEq({ left: allowancePre, right: allowancePost, err: "// THEN: allowance changed with upgrade" });
//     assertEq({ left: allowancePre, right: 500e18, err: "// THEN: allowance not as expected" });
//   }

//   function test_domain_seperator_static() public {
//     bytes32 domain = frxusd.DOMAIN_SEPARATOR();
//     _upgradeFrxUSD();
//     bytes32 domainPost = frxusd.DOMAIN_SEPARATOR();
//     assertEq({ left: domain, right: domainPost, err: "// THEN: domain not static" });
//   }

//   function test_balanceOf_static() public {
//     deal(address(frxusd), al, 250_000e18);
//     uint balPre = frxusd.balanceOf(al);
//     _upgradeFrxUSD();
//     uint balPost = frxusd.balanceOf(al);
//     assertEq({ left: 250_000e18, right: balPre, err: "// THEN: balance initial not expected" });
//     assertEq({ left: balPre, right: balPost, err: "// THEN: balance not static" });
//   }

//   function test_eip712_domain_static() public {
//     (
//       bytes1 fields,
//       string memory name,
//       string memory version,
//       uint256 chainId,
//       address verifyingContract,
//       bytes32 salt,
//       uint256[] memory extensions
//     ) = frxusd.eip712Domain();
//     _upgradeFrxUSD();
//     (
//       bytes1 fieldsPost,
//       string memory namePost,
//       string memory versionPost,
//       uint256 chainIdPost,
//       address verifyingContractPost,
//       bytes32 saltPost,
//       uint256[] memory extensionsPost
//     ) = frxusd.eip712Domain();
//     assertEq({ left: fields, right: fieldsPost, err: "// THEN: `fields` not static" });
//     assertEq({ left: name, right: namePost, err: "// THEN: `name` not static" });
//     assertEq({ left: version, right: versionPost, err: "// THEN: `version` not static" });
//     assertEq({ left: chainId, right: chainIdPost, err: "// THEN: `chainId` not static" });
//     assertEq({ left: verifyingContract, right: verifyingContractPost, err: "// THEN: `verifyingContract` not static" });
//     assertEq({ left: salt, right: saltPost, err: "// THEN: `salt` not static" });
//     assertEq({
//       left: keccak256(abi.encode(extensions)),
//       right: keccak256(abi.encode(extensionsPost)),
//       err: "// THEN: extensions not static"
//     });
//   }

//   function test_totalSupply_static() public {
//     uint pre = frxusd.totalSupply();
//     _upgradeFrxUSD();
//     uint post = frxusd.totalSupply();
//     assertEq({ left: pre, right: post, err: "// THEN: total supply changed" });
//   }

//   /*
//     <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
//     <*>            Reversions for admin gated calls          <*>
//     <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
//     */

//   function test_can_burnMany_tokens_reverts_array_mismatch() public {
//     _upgradeFrxUSD();

//     targets.push(al);
//     targets.push(bob);
//     targets.push(carl);

//     amounts.push(0);
//     amounts.push(0);

//     vm.prank(frxusd.owner());
//     vm.expectRevert(bytes4(keccak256("ArrayMisMatch()")));
//     frxusd.burnMany(targets, amounts);
//   }

//   function test_only_owner_can_pause() public {
//     _upgradeFrxUSD();

//     vm.prank(badActor);
//     vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
//     frxusd.pause();
//   }

//   function test_only_owner_can_unpause() public {
//     test_upgrade_and_pause_successful();

//     vm.prank(badActor);
//     vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
//     frxusd.unpause();
//   }

//   function test_only_owner_can_freeze() public {
//     _upgradeFrxUSD();

//     vm.prank(badActor);
//     vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
//     frxusd.freeze(bob);
//   }

//   function test_only_owner_can_thaw() public {
//     test_upgrade_and_freeze_successful();

//     vm.prank(badActor);
//     vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
//     frxusd.thaw(al);
//   }

//   function test_only_owner_can_freezeMany() public {
//     _upgradeFrxUSD();

//     targets.push(bob);
//     targets.push(carl);

//     vm.prank(badActor);
//     vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
//     frxusd.freezeMany(targets);
//   }

//   function test_only_owner_can_thawMany() public {
//     test_upgrade_and_freezeMany();

//     vm.prank(badActor);
//     vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
//     /// @notice targets array populated w/n `test_upgrade_and_freezeMany`
//     frxusd.thawMany(targets);
//   }

//   function test_only_owner_can_burn() public {
//     _upgradeFrxUSD();

//     vm.prank(badActor);
//     vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
//     frxusd.burn(al, 0);
//   }

//   function test_only_owner_can_burnMany() public {
//     _upgradeFrxUSD();

//     targets.push(al);
//     targets.push(carl);
//     amounts.push(0);
//     amounts.push(0);

//     vm.prank(badActor);
//     vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", badActor));
//     frxusd.burnMany(targets, amounts);
//   }

//   /*
//     <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
//     <*>            Helper functions to move state            <*>
//     <*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*><*>
//     */

//   function _upgradeAndFreeze(address toFreeze) public {
//     _upgradeFrxUSD();

//     vm.prank(frxusd.owner());
//     frxusd.freeze(al);

//     assertEq({ left: frxusd.isFrozen(toFreeze), right: true, err: "// THEN: users account is not frozen" });
//   }

//   function _upgradeFrxUSD() internal {
//     address admin = address(
//       uint160(uint256(vm.load(address(frxusd), bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1))))
//     );
//     IProxy proxyAdmin = IProxy(admin);
//     console.log("The owner of frxUSD: ", proxyAdmin.owner());
//     console.log("The proxy Admin: ", address(proxyAdmin));
//     vm.prank(proxyAdmin.owner());
//     IProxy(address(proxyAdmin)).upgradeAndCall(address(frxusd), address(implV2), hex"");

//     address impl_post = address(
//       uint160(uint256(vm.load(address(frxusd), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
//     );
//     console.log("THe new implementation is: ", impl_post);
//     assertEq({ left: address(implV2), right: impl_post });
//   }

//   function test_case() public {
//     _upgradeFrxUSD();
//   }
// }
