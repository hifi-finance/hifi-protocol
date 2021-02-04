import { Contract, ContractFactory } from "@ethersproject/contracts";
import { ethers } from "hardhat";

let description: string;
if (!process.env.UNISWAP_PRICE_FEED_DESCRIPTION) {
  throw new Error("Please set UNISWAP_PRICE_FEED_DESCRIPTION as an env variable");
} else {
  description = process.env.UNISWAP_PRICE_FEED_DESCRIPTION;
}

let factory: string;
if (!process.env.UNISWAP_PRICE_FEED_FACTORY) {
  throw new Error("Please set UNISWAP_PRICE_FEED_FACTORY as an env variable");
} else {
  factory = process.env.UNISWAP_PRICE_FEED_FACTORY;
}

let windowSize: string;
if (!process.env.UNISWAP_PRICE_FEED_WINDOW_SIZE) {
  throw new Error("Please set UNISWAP_PRICE_FEED_WINDOW_SIZE as an env variable");
} else {
  windowSize = process.env.UNISWAP_PRICE_FEED_WINDOW_SIZE;
}

let granularity: string;
if (!process.env.UNISWAP_PRICE_FEED_GRANULARITY) {
  throw new Error("Please set UNISWAP_PRICE_FEED_GRANULARITY as an env variable");
} else {
  granularity = process.env.UNISWAP_PRICE_FEED_GRANULARITY;
}

let WETH: string;
if (!process.env.UNISWAP_PRICE_FEED_WETH) {
  throw new Error("Please set UNISWAP_PRICE_FEED_WETH as an env variable");
} else {
  WETH = process.env.UNISWAP_PRICE_FEED_WETH;
}

let targetToken: string;
if (!process.env.UNISWAP_PRICE_FEED_TARGET_TOKEN) {
  throw new Error("Please set UNISWAP_PRICE_FEED_TARGET_TOKEN as an env variable");
} else {
  targetToken = process.env.UNISWAP_PRICE_FEED_TARGET_TOKEN;
}

let pair: string;
if (!process.env.UNISWAP_PRICE_FEED_PAIR) {
  throw new Error("Please set UNISWAP_PRICE_FEED_PAIR as an env variable");
} else {
  pair = process.env.UNISWAP_PRICE_FEED_PAIR;
}

let priceFeed: string;
if (!process.env.UNISWAP_PRICE_FEED_PRICE_FEED) {
  throw new Error("Please set UNISWAP_PRICE_FEED_PRICE_FEED as an env variable");
} else {
  priceFeed = process.env.UNISWAP_PRICE_FEED_PRICE_FEED;
}


async function main(): Promise<void> {
  const uniswapPriceFeedFactory: ContractFactory = await ethers.getContractFactory("UniswapPriceFeed");
  const uniswapPriceFeed: Contract = await uniswapPriceFeedFactory.deploy(
    description,
    factory,
    windowSize,
    granularity,
    WETH,
    targetToken,
    pair,
    priceFeed,
  );
  await uniswapPriceFeed.deployed();

  console.log("UniswapPriceFeed deployed to: ", uniswapPriceFeed.address);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
