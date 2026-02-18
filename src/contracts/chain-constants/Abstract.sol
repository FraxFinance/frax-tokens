// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

library Abstract {
    address internal constant FPIOFT = 0x580F2ee1476eDF4B1760bd68f6AaBaD57dec420E;
    address internal constant FRXETHOFT = 0xc7Ab797019156b543B7a3fBF5A99ECDab9eb4440;
    address internal constant FRXUSDOFT = 0xEa77c590Bb36c43ef7139cE649cFBCFD6163170d;
    address internal constant SFRXETHOFT = 0xFD78FD3667DeF2F1097Ed221ec503AE477155394;
    address internal constant SFRXUSDOFT = 0x9F87fbb47C33Cd0614E43500b9511018116F79eE;
    address internal constant WFRAXOFT = 0xAf01aE13Fb67AD2bb2D76f29A83961069a5F245F;
    address internal constant REMOTEHOP = 0xc5e4A0cfef8D801278927C25fB51C1DB7b69dDFb;
    address internal constant REMOTEMINTREDEEMHOP = 0xa05E9F9B97c963B5651ed6A50Fae46625a8C400b;
}

abstract contract AddressHelperAbstract is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
        vm.label(0x580F2ee1476eDF4B1760bd68f6AaBaD57dec420E, "Constants.ABS_FPIOFT");
        vm.label(0xc7Ab797019156b543B7a3fBF5A99ECDab9eb4440, "Constants.ABS_FRXETHOFT");
        vm.label(0xEa77c590Bb36c43ef7139cE649cFBCFD6163170d, "Constants.ABS_FRXUSDOFT");
        vm.label(0xFD78FD3667DeF2F1097Ed221ec503AE477155394, "Constants.ABS_SFRXETHOFT");
        vm.label(0x9F87fbb47C33Cd0614E43500b9511018116F79eE, "Constants.ABS_SFRXUSDOFT");
        vm.label(0xAf01aE13Fb67AD2bb2D76f29A83961069a5F245F, "Constants.ABS_WFRAXOFT");
        vm.label(0xc5e4A0cfef8D801278927C25fB51C1DB7b69dDFb, "Constants.ABS_REMOTEHOP");
        vm.label(0xa05E9F9B97c963B5651ed6A50Fae46625a8C400b, "Constants.ABS_REMOTEMINTREDEEMHOP");
    }
}
