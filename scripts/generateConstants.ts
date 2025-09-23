import * as fs from "fs/promises";
import path from "path";
import { isAddress } from "viem"

import * as constants from "./constants";

const networkPrefixes = {
  Abstract: "ABS",
  Aptos: "APT",
  Arbitrum: "ARBI",
  Aurora: "AUR",
  Avalanche: "AVAX",
  Base: "BASE",
  Bera: "BERA",
  Blast: "BLAST",
  Bsc: "BSC",
  Fantom: "FTM",
  FraxtalL1Devnet: "FXTL_L1_DN",
  FraxtalL2Devnet: "FXTL_L2_DN",
  FraxtalL2: "FXTL",
  FraxtalTestnetL1: "FXTL_TN_L1",
  FraxtalTestnetL2: "FXTL_TN_L2",
  Holesky: "HOLESKY",
  Hyperliquid: "HYPE",
  Ink: "INK",
  Katana: "KTN",
  Mainnet: "ETH",
  Moonbeam: "MNBM",
  Moonriver: "MOVR",
  Optimism: "OPTI",
  Plumephoenix: "PLUME",
  Polygon: "POLY",
  PolygonzkEVM: "POLY_ZKEVM",
  Scroll: "SCROLL",
  Sei: "SEI",
  Solana: "SOL",
  Sonic: "SONIC",
  Unichain: "UNI",
  Worldchain: "WRLD",
  Linea: "LINEA",
  XLayer: "XLAYER",
  Zksync: "ZKSYNC"
};

const REMOVE_DUPLICATE_LABELS = false;

async function main() {
  // Get all the network names
  const networks = Object.keys(constants);

  // Prepare seen/duplicate values
  const seenValues = [];

  const headerString = `// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

	`

  let finalConstantsString = headerString;

  // Generate the files
  for (let n = 0; n < networks.length; n++) {
    const networkName = networks[n];
    const outputString = await handleSingleNetwork(networkName, constants[networkName], seenValues);

    const finalString = headerString + outputString;
    finalConstantsString = finalConstantsString + outputString;
    await fs.writeFile(path.resolve("src/contracts/chain-constants", `${networkName}.sol`), finalString);
  }
  await fs.writeFile(path.resolve("src/", `Constants.sol`), finalConstantsString);
}

async function handleSingleNetwork(networkName, constants, seenValues) {
  let numberValues: any[] = [];
  const constantString = Object.entries(constants)
    .map(([key, value]) => {
      if (typeof value === "string") {
        // Determine whether it is an address or a string
        if (value.startsWith("0x")) {
          if (isAddress(value)) { return `    address internal constant ${key} = ${value};`; }
          else if (value.length === 66) {
            return `    bytes32 internal constant ${key} = ${value};`;
          } else {
            throw new Error("Unidentifed constant type")
          }
        }
        return `    string internal constant ${key} = "${value}";`;
      } else {
        // number

        // Note the value is a number
        numberValues.push(value);

        return `    uint256 internal constant ${key} = ${value};`;
      }
    })
    .join("\n");

  // Remove certain values from being labeled
  let constantsToLabel = {};
  Object.entries(constants).forEach(([key, value]) => {
    // Check if the value has been labeled already
    const alreadySeen = REMOVE_DUPLICATE_LABELS ? seenValues.includes(value) : false;

    // Check if the value is a number
    const isANumber = numberValues.includes(value);

    // Check for rejects
    if (alreadySeen) {
      // Do not label already-seen addresses (optional)
      console.log(`Removing duplicate value ${value}`);
    } else if (isANumber) {
      // Do not label numbers
      console.log(`Removing number value ${value}`);
    } else {
      // Otherwise, it can be labeled
      constantsToLabel[key] = value;
    }
  });

  // Generate the labels for the entries
  const labelStrings = Object.entries(constantsToLabel)
    .map(([key, value]) => {
      // Add the value to the seen list
      seenValues.push(value);

      // Return the string
      return `        vm.label(${value}, "Constants.${networkPrefixes[networkName]}_${key}");`;
    })
    .join("\n");
  const contractString = `library ${networkName} {
${constantString}
}
`;

  // if (networkName == "Mainnet") {
  const constantsHelper = `
abstract contract AddressHelper${networkName} is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
${labelStrings}
    }
}
`;
  return contractString + constantsHelper;
  // }
  // return contractString;
}

main();
