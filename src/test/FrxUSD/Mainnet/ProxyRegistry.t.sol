// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/FraxTest.sol";
import "src/Constants.sol" as Constants;
import { IFrxUSD } from "src/contracts/ethereum/frxUSD/IFrxUSD.sol";
import { IProxy } from "src/test/helpers/IProxy.sol";

contract FrxUSD_Mainnet_ProxyRegistry is FraxTest {
    struct Proxy1967State {
        string name;
        address proxy;
        address proxyAdmin;
        address proxyAdminOwner;
        address proxyImplementation;
        string version;
    }

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("MAINNET_URL"));
    }

    function test_proxySlotValues() public view {
        Proxy1967State[1] memory proxies = [
            Proxy1967State({
                name: "frxUSD",
                proxy: Constants.Ethereum.FRXUSD,
                proxyAdmin: Constants.Ethereum.FRXUSD_PROXY_ADMIN,
                proxyAdminOwner: Constants.Ethereum.FRXUSD_PROXY_ADMIN_OWNER,
                proxyImplementation: Constants.Ethereum.FRXUSD_IMPLEMENTATION,
                version: "3.0.0"
            })
        ];

        for (uint256 i; i < proxies.length; ++i) {
            Proxy1967State memory p = proxies[i];

            address impl = address(
                uint160(uint256(vm.load(p.proxy, bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
            );
            address admin = address(
                uint160(uint256(vm.load(p.proxy, bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1))))
            );
            address adminOwner = IProxy(admin).owner();
            string memory ver = IFrxUSD(p.proxy).version();

            assertEq({
                left: p.proxyImplementation,
                right: impl,
                err: string(abi.encodePacked("// THEN: impl does not match -- ", p.name))
            });
            assertEq({
                left: p.proxyAdmin,
                right: admin,
                err: string(abi.encodePacked("// THEN: admin does not match -- ", p.name))
            });
            assertEq({
                left: p.proxyAdminOwner,
                right: adminOwner,
                err: string(abi.encodePacked("// THEN: admin owner does not match -- ", p.name))
            });
            assertEq({
                left: p.version,
                right: ver,
                err: string(abi.encodePacked("// THEN: version does not match -- ", p.name))
            });
        }
    }
}
