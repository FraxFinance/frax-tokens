// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

library Plumephoenix {
    address internal constant FPIOFT = 0x90581eCa9469D8D7F5D3B60f4715027aDFCf7927;
    address internal constant FRXETHOFT = 0x43eDD7f3831b08FE70B7555ddD373C8bF65a9050;
    address internal constant FRXUSDOFT = 0x80Eede496655FB9047dd39d9f418d5483ED600df;
    address internal constant SFRXETHOFT = 0x3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45;
    address internal constant SFRXUSDOFT = 0x5Bff88cA1442c2496f7E475E9e7786383Bc070c0;
    address internal constant WFRAXOFT = 0x64445f0aecC51E94aD52d8AC56b7190e764E561a;
    address internal constant REMOTEHOP = 0x6cA98f43719231d38F6426DB64C7F3D5C7CE7876;
    address internal constant REMOTEMINTREDEEMHOP = 0xa71f2204EDDB8d84F411A0C712687FAe5002e7Fb;
}

abstract contract AddressHelperPlumephoenix is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
        vm.label(0x90581eCa9469D8D7F5D3B60f4715027aDFCf7927, "Constants.PLUME_FPIOFT");
        vm.label(0x43eDD7f3831b08FE70B7555ddD373C8bF65a9050, "Constants.PLUME_FRXETHOFT");
        vm.label(0x80Eede496655FB9047dd39d9f418d5483ED600df, "Constants.PLUME_FRXUSDOFT");
        vm.label(0x3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45, "Constants.PLUME_SFRXETHOFT");
        vm.label(0x5Bff88cA1442c2496f7E475E9e7786383Bc070c0, "Constants.PLUME_SFRXUSDOFT");
        vm.label(0x64445f0aecC51E94aD52d8AC56b7190e764E561a, "Constants.PLUME_WFRAXOFT");
        vm.label(0x6cA98f43719231d38F6426DB64C7F3D5C7CE7876, "Constants.PLUME_REMOTEHOP");
        vm.label(0xa71f2204EDDB8d84F411A0C712687FAe5002e7Fb, "Constants.PLUME_REMOTEMINTREDEEMHOP");
    }
}
