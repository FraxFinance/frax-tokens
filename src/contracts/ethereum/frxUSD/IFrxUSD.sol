pragma solidity ^0.8.0;

import { IFrxUSD2 } from "src/contracts/ethereum/frxUSD/versioning/IFrxUSD2.sol";

interface IFrxUSD is IFrxUSD2 {
    function owner() external view returns (address);

    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}
