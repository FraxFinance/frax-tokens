"use strict";
var __createBinding =
  (this && this.__createBinding) ||
  (Object.create
    ? function (o, m, k, k2) {
        if (k2 === undefined) k2 = k;
        var desc = Object.getOwnPropertyDescriptor(m, k);
        if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
          desc = {
            enumerable: true,
            get: function () {
              return m[k];
            },
          };
        }
        Object.defineProperty(o, k2, desc);
      }
    : function (o, m, k, k2) {
        if (k2 === undefined) k2 = k;
        o[k2] = m[k];
      });
var __setModuleDefault =
  (this && this.__setModuleDefault) ||
  (Object.create
    ? function (o, v) {
        Object.defineProperty(o, "default", { enumerable: true, value: v });
      }
    : function (o, v) {
        o["default"] = v;
      });
var __importStar =
  (this && this.__importStar) ||
  (function () {
    var ownKeys = function (o) {
      ownKeys =
        Object.getOwnPropertyNames ||
        function (o) {
          var ar = [];
          for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
          return ar;
        };
      return ownKeys(o);
    };
    return function (mod) {
      if (mod && mod.__esModule) return mod;
      var result = {};
      if (mod != null)
        for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
      __setModuleDefault(result, mod);
      return result;
    };
  })();
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod };
  };
Object.defineProperty(exports, "__esModule", { value: true });
const fs = __importStar(require("fs/promises"));
const path_1 = __importDefault(require("path"));
const constants = __importStar(require("./constants"));
const networkPrefixes = {
  Abstract: "ABS",
  Aptos: "APT",
  Arbitrum: "ARBI",
  Aurora: "AUR",
  Avalanche: "AVAX",
  BASE: "BASE",
  BERA: "BERA",
  BLAST: "BLAST",
  BSC: "BSC",
  Ethereum: "ETH",
  Fantom: "FTM",
  FraxtalL1Devnet: "FXTL_L1_DN",
  FraxtalL2Devnet: "FXTL_L2_DN",
  FraxtalL2: "FXTL",
  FraxtalTestnetL1: "FXTL_TN_L1",
  FraxtalTestnetL2: "FXTL_TN_L2",
  Holesky: "HOLESKY",
  Hyperliquid: "HYPE",
  Katana: "KTN",
  Mainnet: "ETH",
  Moonbeam: "MNBM",
  Moonriver: "MOVR",
  Optimism: "OPTI",
  Polygon: "POLY",
  PolygonzkEVM: "POLY_ZKEVM",
  Scroll: "SCROLL",
  Sei: "SEI",
  Solana: "SOL",
  Sonic: "SONIC",
  Unichain: "UNI",
  Worldchain: "WRLD",
  Linea: "LINEA",
  Zksync: "ZKSYNC",
};
const REMOVE_DUPLICATE_LABELS = false;
async function main() {
  // Get all the network names
  const networks = Object.keys(constants);
  // Prepare seen/duplicate values
  const seenValues = [];
  // Generate the files
  for (let n = 0; n < networks.length; n++) {
    const networkName = networks[n];
    const outputString = await handleSingleNetwork(networkName, constants[networkName], seenValues);
    const finalString =
      `// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

	` + outputString;
    await fs.writeFile(path_1.default.resolve("src/contracts/chain-constants", `${networkName}.sol`), finalString);
  }
}
async function handleSingleNetwork(networkName, constants, seenValues) {
  let numberValues = [];
  const constantString = Object.entries(constants)
    .map(([key, value]) => {
      if (typeof value === "string") {
        // Determine whether it is an address or a string
        if (value.startsWith("0x")) {
          return `    address internal constant ${key} = ${value};`;
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
