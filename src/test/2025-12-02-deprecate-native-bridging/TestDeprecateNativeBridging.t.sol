pragma solidity ^0.8.0;

import "src/script/fraxtal/2025-12-02-deprecate-nativing-bridging/DeprecateNativeBridging.s.sol";
import "frax-std/FraxTest.sol";
import { ERC20PermitPermissionedNonBridgeableMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedNonBridgeableMintable.sol";

contract TestDeprecateNativeBridging is FraxTest {
    DeprecateNativeBridging public script;

    function setUp() public {
        vm.createSelectFork("https://rpc.frax.com", 28_000_000);

        script = new DeprecateNativeBridging();
        script.setUp();
        script.runTest();
    }

    function test_CannotBridgeNative() public {
        assertBridgeReverted(FRXUSD_PROXY);
        assertBridgeReverted(SFRXUSD_PROXY);
        assertBridgeReverted(FPI_PROXY);
        assertBridgeReverted(FRXBTC_PROXY);
        assertBridgeReverted(FRXETH_PROXY);
        assertBridgeReverted(SFRXETH_PROXY);
    }

    function assertBridgeReverted(address token) internal {
        vm.expectRevert(ERC20PermitPermissionedNonBridgeableMintable.Deprecated.selector);
        ERC20PermitPermissionedNonBridgeableMintable(token).mint(address(1), 1 ether);

        vm.expectRevert(ERC20PermitPermissionedNonBridgeableMintable.Deprecated.selector);
        ERC20PermitPermissionedNonBridgeableMintable(token).burn(address(1), 1 ether);
    }
}
