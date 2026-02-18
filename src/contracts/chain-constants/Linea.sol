// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

library Linea {
    address internal constant FPIOFT = 0xDaF72Aa849d3C4FAA8A9c8c99f240Cf33dA02fc4;
    address internal constant FRXETHOFT = 0xB1aFD04774c02AE84692619448B08BA79F19b1ff;
    address internal constant FRXUSDOFT = 0xC7346783f5e645aa998B106Ef9E7f499528673D8;
    address internal constant SFRXETHOFT = 0x383Eac7CcaA89684b8277cBabC25BCa8b13B7Aa2;
    address internal constant SFRXUSDOFT = 0x592a48c0FB9c7f8BF1701cB0136b90DEa2A5B7B6;
    address internal constant WFRAXOFT = 0x5217Ab28ECE654Aab2C68efedb6A22739df6C3D5;
    address internal constant REMOTEHOP = 0x6cA98f43719231d38F6426DB64C7F3D5C7CE7876;
    address internal constant REMOTEMINTREDEEMHOP = 0xa71f2204EDDB8d84F411A0C712687FAe5002e7Fb;
}

abstract contract AddressHelperLinea is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
        vm.label(0xDaF72Aa849d3C4FAA8A9c8c99f240Cf33dA02fc4, "Constants.LINEA_FPIOFT");
        vm.label(0xB1aFD04774c02AE84692619448B08BA79F19b1ff, "Constants.LINEA_FRXETHOFT");
        vm.label(0xC7346783f5e645aa998B106Ef9E7f499528673D8, "Constants.LINEA_FRXUSDOFT");
        vm.label(0x383Eac7CcaA89684b8277cBabC25BCa8b13B7Aa2, "Constants.LINEA_SFRXETHOFT");
        vm.label(0x592a48c0FB9c7f8BF1701cB0136b90DEa2A5B7B6, "Constants.LINEA_SFRXUSDOFT");
        vm.label(0x5217Ab28ECE654Aab2C68efedb6A22739df6C3D5, "Constants.LINEA_WFRAXOFT");
        vm.label(0x6cA98f43719231d38F6426DB64C7F3D5C7CE7876, "Constants.LINEA_REMOTEHOP");
        vm.label(0xa71f2204EDDB8d84F411A0C712687FAe5002e7Fb, "Constants.LINEA_REMOTEMINTREDEEMHOP");
    }
}
