pragma solidity ^0.8.0;

import { ERC20PermitPermissionedNonBridgeableMintable } from "src/contracts/fraxtal/shared/ERC20PermitPermissionedNonBridgeableMintable.sol";
import { Initializable } from "@openzeppelin/contracts-5.2.0/proxy/utils/Initializable.sol";

contract ERC20PPNBMInitializable is ERC20PermitPermissionedNonBridgeableMintable, Initializable {
    constructor(
        string memory _name,
        string memory _version
    ) ERC20PermitPermissionedNonBridgeableMintable(_name, _version) {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _timelock
    ) external initializer {
        assembly {
            // Helper: use scratch space at 0x00 to hash slot numbers
            function hashSlot(slot) -> dataSlot {
                mstore(0x00, slot)
                dataSlot := keccak256(0x00, 0x20)
            }

            function storeString(slot, str) {
                let len := mload(str)
                switch gt(len, 31)
                case 0 {
                    // Short string: data in high bytes, length * 2 in lowest byte
                    sstore(slot, or(mload(add(str, 0x20)), mul(len, 2)))
                }
                case 1 {
                    // Long string: store (length * 2 + 1) in slot, data in keccak256(slot)
                    sstore(slot, add(mul(len, 2), 1))
                    let dataSlot := hashSlot(slot)
                    for {
                        let i := 0
                    } lt(i, len) {
                        i := add(i, 0x20)
                    } {
                        sstore(add(dataSlot, div(i, 0x20)), mload(add(add(str, 0x20), i)))
                    }
                }
            }

            // _name (slot 3)
            storeString(3, _name)

            // _symbol (slot 4)
            storeString(4, _symbol)

            // owner (slot 8)
            sstore(8, _owner)

            // timelock_address (slot 10)
            sstore(10, _timelock)
        }
    }
}
