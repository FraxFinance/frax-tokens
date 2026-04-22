import * as fs from "fs/promises";
import path from "path";
import { utils } from "ethers";
const { getAddress } = utils;

import * as constants from "./constants";

const networkPrefixes: Record<string, string> = {
  Abstract: "ABS",
  Aptos: "APT",
  Arbitrum: "ARBI",
  Aurora: "AUR",
  Avalanche: "AVAX",
  Base: "BASE",
  Bera: "BERA",
  Blast: "BLAST",
  BSC: "BSC",
  Ethereum: "ETH",
  Fantom: "FTM",
  FraxtalL1Devnet: "FXTL_L1_DN",
  FraxtalL2: "FXTL",
  FraxtalL2Devnet: "FXTL_L2_DN",
  FraxtalTestnetL1: "FXTL_TN_L1",
  FraxtalTestnetL2: "FXTL_TN_L2",
  Holesky: "HOLESKY",
  Hyperliquid: "HYPE",
  Ink: "INK",
  Katana: "KTN",
  Linea: "LINEA",
  Mainnet: "ETH",
  Mode: "MODE",
  Moonbeam: "MNBM",
  Moonriver: "MOVR",
  Optimism: "OPTI",
  Plumephoenix: "PLUME",
  Polygon: "POLY",
  PolygonzkEVM: "POLY_ZKEVM",
  Scroll: "SCROLL",
  Solana: "SOL",
  Sonic: "SONIC",
  Unichain: "UNI",
  Worldchain: "WRLD",
  XLayer: "XLYR",
  ZkSync: "ZKSYNC",
};

async function main() {
  const networks = Object.keys(constants);
  const outputStrings = networks.map((networkName) => {
    return handleSingleNetwork(networkName, constants[networkName]);
  });

  const finalString =
    `// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// **NOTE** Generated code, do not modify.  Run 'npm run generate:constants'.

import { TestBase } from "forge-std/Test.sol";

` + outputStrings.join("\n");

  await fs.writeFile(path.resolve("src", "Constants.sol"), finalString);
}

function handleSingleNetwork(networkName: string, networkConstants: Record<string, unknown>): string {
  const numberValues: unknown[] = [];

  const isAddress = (v: string) => v.startsWith("0x") && v.length === 42;
  const isBytes32 = (v: string) => v.startsWith("0x") && v.length > 42;

  const constantString = Object.entries(networkConstants)
    .map(([key, value]) => {
      if (typeof value === "string") {
        if (isAddress(value)) {
          return `    address internal constant ${key} = ${getAddress(value)};`;
        }
        if (isBytes32(value)) {
          return `    bytes32 internal constant ${key} = ${value};`;
        }
        return `    string internal constant ${key} = "${value}";`;
      } else {
        numberValues.push(value);
        return `    uint256 internal constant ${key} = ${value};`;
      }
    })
    .join("\n");

  const prefix = networkPrefixes[networkName] ?? networkName.toUpperCase();

  const labelStrings = Object.entries(networkConstants)
    .filter(([, value]) => typeof value === "string" && isAddress(value as string))
    .map(([key, value]) => {
      return `        vm.label(${getAddress(value as string)}, "Constants.${prefix}_${key}");`;
    })
    .join("\n");

  const libraryString = `library ${networkName} {
${constantString}
}
`;

  const helperString = `abstract contract AddressHelper${networkName} is TestBase {
    constructor() {
        labelConstants();
    }

    function labelConstants() public {
${labelStrings}
    }
}
`;

  return libraryString + "\n" + helperString;
}

main();
