// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

library Aurora {
    address internal constant FPIOFT = 0x90581eCa9469D8D7F5D3B60f4715027aDFCf7927;
    address internal constant FRXETHOFT = 0x43eDD7f3831b08FE70B7555ddD373C8bF65a9050;
    address internal constant FRXUSDOFT = 0x80Eede496655FB9047dd39d9f418d5483ED600df;
    address internal constant SFRXETHOFT = 0x3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45;
    address internal constant SFRXUSDOFT = 0x5Bff88cA1442c2496f7E475E9e7786383Bc070c0;
    address internal constant WFRAXOFT = 0x64445f0aecC51E94aD52d8AC56b7190e764E561a;
    address internal constant REMOTEHOP = 0x53e36C8380Ff62D7964BFa4868A0045E58A52344;
    address internal constant REMOTEMINTREDEEMHOP = 0x8EbB34b1880B2EA5e458082590B3A2c9Ea7C41A2;
}

abstract contract AddressHelperAurora is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
        vm.label(0x90581eCa9469D8D7F5D3B60f4715027aDFCf7927, "Constants.AUR_FPIOFT");
        vm.label(0x43eDD7f3831b08FE70B7555ddD373C8bF65a9050, "Constants.AUR_FRXETHOFT");
        vm.label(0x80Eede496655FB9047dd39d9f418d5483ED600df, "Constants.AUR_FRXUSDOFT");
        vm.label(0x3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45, "Constants.AUR_SFRXETHOFT");
        vm.label(0x5Bff88cA1442c2496f7E475E9e7786383Bc070c0, "Constants.AUR_SFRXUSDOFT");
        vm.label(0x64445f0aecC51E94aD52d8AC56b7190e764E561a, "Constants.AUR_WFRAXOFT");
        vm.label(0x53e36C8380Ff62D7964BFa4868A0045E58A52344, "Constants.AUR_REMOTEHOP");
        vm.label(0x8EbB34b1880B2EA5e458082590B3A2c9Ea7C41A2, "Constants.AUR_REMOTEMINTREDEEMHOP");
    }
}
