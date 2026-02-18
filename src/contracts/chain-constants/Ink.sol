// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

library Ink {
    address internal constant FPIOFT = 0x90581eCa9469D8D7F5D3B60f4715027aDFCf7927;
    address internal constant FRXETHOFT = 0x43eDD7f3831b08FE70B7555ddD373C8bF65a9050;
    address internal constant FRXUSDOFT = 0x80Eede496655FB9047dd39d9f418d5483ED600df;
    address internal constant SFRXETHOFT = 0x3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45;
    address internal constant SFRXUSDOFT = 0x5Bff88cA1442c2496f7E475E9e7786383Bc070c0;
    address internal constant WFRAXOFT = 0x64445f0aecC51E94aD52d8AC56b7190e764E561a;
    address internal constant REMOTEHOP = 0x7a07D606c87b7251c2953A30Fa445d8c5F856C7A;
    address internal constant REMOTEMINTREDEEMHOP = 0x452420df4AC1e3db5429b5FD629f3047482C543C;
}

abstract contract AddressHelperInk is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
        vm.label(0x90581eCa9469D8D7F5D3B60f4715027aDFCf7927, "Constants.INK_FPIOFT");
        vm.label(0x43eDD7f3831b08FE70B7555ddD373C8bF65a9050, "Constants.INK_FRXETHOFT");
        vm.label(0x80Eede496655FB9047dd39d9f418d5483ED600df, "Constants.INK_FRXUSDOFT");
        vm.label(0x3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45, "Constants.INK_SFRXETHOFT");
        vm.label(0x5Bff88cA1442c2496f7E475E9e7786383Bc070c0, "Constants.INK_SFRXUSDOFT");
        vm.label(0x64445f0aecC51E94aD52d8AC56b7190e764E561a, "Constants.INK_WFRAXOFT");
        vm.label(0x7a07D606c87b7251c2953A30Fa445d8c5F856C7A, "Constants.INK_REMOTEHOP");
        vm.label(0x452420df4AC1e3db5429b5FD629f3047482C543C, "Constants.INK_REMOTEMINTREDEEMHOP");
    }
}
