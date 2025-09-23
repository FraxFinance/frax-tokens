// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

library Base {
    address internal constant FPIOFT = 0xEEdd3A0DDDF977462A97C1F0eBb89C3fbe8D084B;
    address internal constant FRXETHOFT = 0x7eb8d1E4E2D0C8b9bEDA7a97b305cF49F3eeE8dA;
    address internal constant FRXUSDOFT = 0xe5020A6d073a794B6E7f05678707dE47986Fb0b6;
    address internal constant SFRXETHOFT = 0x192e0C7Cc9B263D93fa6d472De47bBefe1Fb12bA;
    address internal constant SFRXUSDOFT = 0x91A3f8a8d7a881fBDfcfEcd7A2Dc92a46DCfa14e;
    address internal constant WFRAXOFT = 0x0CEAC003B0d2479BebeC9f4b2EBAd0a803759bbf;
    address internal constant REMOTEHOP = 0x3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45;
    address internal constant REMOTEMINTREDEEMHOP = 0x73382eb28F35d80Df8C3fe04A3EED71b1aFce5dE;
}

abstract contract AddressHelperBase is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
        vm.label(0xEEdd3A0DDDF977462A97C1F0eBb89C3fbe8D084B, "Constants.BASE_FPIOFT");
        vm.label(0x7eb8d1E4E2D0C8b9bEDA7a97b305cF49F3eeE8dA, "Constants.BASE_FRXETHOFT");
        vm.label(0xe5020A6d073a794B6E7f05678707dE47986Fb0b6, "Constants.BASE_FRXUSDOFT");
        vm.label(0x192e0C7Cc9B263D93fa6d472De47bBefe1Fb12bA, "Constants.BASE_SFRXETHOFT");
        vm.label(0x91A3f8a8d7a881fBDfcfEcd7A2Dc92a46DCfa14e, "Constants.BASE_SFRXUSDOFT");
        vm.label(0x0CEAC003B0d2479BebeC9f4b2EBAd0a803759bbf, "Constants.BASE_WFRAXOFT");
        vm.label(0x3Ec3849C33291a9eF4c5dB86De593EB4A37fDe45, "Constants.BASE_REMOTEHOP");
        vm.label(0x73382eb28F35d80Df8C3fe04A3EED71b1aFce5dE, "Constants.BASE_REMOTEMINTREDEEMHOP");
    }
}
