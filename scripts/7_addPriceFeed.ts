import { Contract, ContractFactory } from "@ethersproject/contracts";
import { ethers } from "hardhat";

import {
  ChainlinkOperatorFactory,
} from '../typechain';

async function main(): Promise<void> {

}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
