import fsExtra from "fs-extra";
import hre from "hardhat";
import path from "path";

import { Artifact } from "hardhat/types";

const artifactsDir: string = path.join(__dirname, "..", "artifacts");
const contracts: string[] = [
  "Admin",
  "AdminInterface",
  "AggregatorV3Interface",
  "BalanceSheet",
  "BalanceSheetInterface",
  "BatterseaTargetV1",
  "BatterseaTargetV1Interface",
  "ChainlinkOperator",
  "ChainlinkOperatorInterface",
  "Erc20",
  "Erc20Interface",
  "Erc20Permit",
  "Erc20PermitInterface",
  "Fintroller",
  "FintrollerInterface",
  "FyToken",
  "FyTokenInterface",
  "RedemptionPool",
  "RedemptionPoolInterface",
  "StablecoinPriceFeed",
];
const tempArtifactsDir: string = path.join(__dirname, "..", "artifacts-temp");
const typeChainDir: string = path.join(__dirname, "..", "typechain");
const tempTypeChainDir: string = path.join(__dirname, "..", "typechain-temp");

async function writeArtifactToFile(contractName: string): Promise<void> {
  const artifact: Artifact = await hre.artifacts.readArtifact(contractName);
  await fsExtra.writeJson(path.join(tempArtifactsDir, contractName + ".json"), artifact, { spaces: 2 });
}

async function moveTypeChainBinding(contractName: string): Promise<void> {
  const bindingPath: string = path.join(typeChainDir, contractName + ".d.ts");

  if (fsExtra.existsSync(bindingPath) == false) {
    throw new Error("TypeChain binding " + contractName + ".d.ts not found");
  }

  await fsExtra.move(bindingPath, path.join(tempTypeChainDir, contractName + ".d.ts"));
}

async function prepareArtifacts(): Promise<void> {
  await fsExtra.ensureDir(tempArtifactsDir);
  const npmIgnorePath: string = path.join(tempArtifactsDir, ".npmignore");
  await fsExtra.ensureFile(npmIgnorePath);
  await fsExtra.writeFile(npmIgnorePath, ".DS_Store\n.npmignore");

  for (const contract of contracts) {
    await writeArtifactToFile(contract);
  }

  await fsExtra.remove(artifactsDir);
  await fsExtra.move(tempArtifactsDir, artifactsDir);
}

async function prepareTypeChainBindings(): Promise<void> {
  await fsExtra.ensureDir(tempTypeChainDir);

  for (const contract of contracts) {
    await moveTypeChainBinding(contract);
  }

  await fsExtra.remove(typeChainDir);
  await fsExtra.move(tempTypeChainDir, typeChainDir);
}

async function main(): Promise<void> {
  if (fsExtra.existsSync(artifactsDir) === false) {
    throw new Error("Please generate the Hardhat artifacts before running this script");
  }

  if (fsExtra.existsSync(typeChainDir) === false) {
    throw new Error("Please generate the TypeChain bindings before running this script");
  }

  await prepareArtifacts();
  await prepareTypeChainBindings();

  console.log("Contract artifacts and TypeChain bindings successfully prepared for npm");
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
