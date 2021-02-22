import { MockContract } from "ethereum-waffle";
import { One } from "@ethersproject/constants";
import { Signer } from "@ethersproject/abstract-signer";

import { ChainlinkOperator } from "../../typechain/ChainlinkOperator";
import { Fintroller } from "../../typechain/Fintroller";
import { GodModeBalanceSheet } from "../../typechain/GodModeBalanceSheet";
import { GodModeFyToken } from "../../typechain/GodModeFyToken";
import { GodModeRedemptionPool } from "../../typechain/GodModeRedemptionPool";
import { UniswapV2PairPriceFeed } from "../../typechain/UniswapV2PairPriceFeed";

import {
  deployChainlinkOperator,
  deployFintroller,
  deployGodModeBalanceSheet,
  deployGodModeFyToken,
  deployGodModeRedemptionPool,
  deployUniswapV2PairPriceFeed,
  deployUnderlyingPriceFeeds,
} from "../deployers";
import {
  deployStubBalanceSheet,
  deployStubChainlinkOperator,
  deployStubCollateral,
  deployStubCollateralPriceFeed,
  deployStubFintroller,
  deployStubRedemptionPool,
  deployStubFyToken,
  deployStubUnderlying,
  deployStubUniswapV2Pair,
} from "./stubs";
import { fyTokenConstants } from "../../helpers/constants";

type UnitFixtureUniswapV2PairPriceFeedReturnType = {
  uniswapV2PairPriceFeed: UniswapV2PairPriceFeed;
  uniswapV2Pair: MockContract;
}

export async function unitFixtureUniswapV2PairPriceFeed(signers: Signer[]): Promise<UnitFixtureUniswapV2PairPriceFeedReturnType> {
  const deployer: Signer = signers[0];

  const uniswapV2Pair: MockContract = await deployStubUniswapV2Pair(deployer);

  const underlyingOracles = await deployUnderlyingPriceFeeds(deployer);

  const uniswapV2PairPriceFeed: UniswapV2PairPriceFeed = await deployUniswapV2PairPriceFeed(
    deployer,
    'WBTC-UNI/ETH',
    uniswapV2Pair.address,
    [underlyingOracles[0].address, underlyingOracles[1].address],
  );

  return { uniswapV2PairPriceFeed, uniswapV2Pair };
}

type UnitFixtureBalanceSheetReturnType = {
  balanceSheet: GodModeBalanceSheet;
  collateral: MockContract;
  fintroller: MockContract;
  oracle: MockContract;
  underlying: MockContract;
  fyToken: MockContract;
};

export async function unitFixtureBalanceSheet(signers: Signer[]): Promise<UnitFixtureBalanceSheetReturnType> {
  const deployer: Signer = signers[0];

  const collateral: MockContract = await deployStubCollateral(deployer);
  const underlying: MockContract = await deployStubUnderlying(deployer);

  const oracle: MockContract = await deployStubChainlinkOperator(deployer);
  const fintroller: MockContract = await deployStubFintroller(deployer);
  await fintroller.mock.oracle.returns(oracle.address);

  const fyToken: MockContract = await deployStubFyToken(deployer);
  await fyToken.mock.collateral.returns(collateral.address);
  await fyToken.mock.collateralPrecisionScalar.returns(One);
  await fyToken.mock.underlying.returns(underlying.address);
  await fyToken.mock.underlyingPrecisionScalar.returns(One);

  const balanceSheet: GodModeBalanceSheet = await deployGodModeBalanceSheet(deployer, fintroller.address);
  return { balanceSheet, collateral, fintroller, oracle, underlying, fyToken };
}

type UnitFixtureChainlinkOperatorReturnType = {
  collateral: MockContract;
  collateralPriceFeed: MockContract;
  oracle: ChainlinkOperator;
};

export async function unitFixtureChainlinkOperator(signers: Signer[]): Promise<UnitFixtureChainlinkOperatorReturnType> {
  const deployer: Signer = signers[0];
  const collateral: MockContract = await deployStubCollateral(deployer);
  const collateralPriceFeed: MockContract = await deployStubCollateralPriceFeed(deployer);
  const oracle: ChainlinkOperator = await deployChainlinkOperator(deployer);
  return { collateral, collateralPriceFeed, oracle };
}

type UnitFixtureFintrollerReturnType = {
  fintroller: Fintroller;
  fyToken: MockContract;
  oracle: MockContract;
};

export async function unitFixtureFintroller(signers: Signer[]): Promise<UnitFixtureFintrollerReturnType> {
  const deployer: Signer = signers[0];
  const oracle: MockContract = await deployStubChainlinkOperator(deployer);
  const fyToken: MockContract = await deployStubFyToken(deployer);
  const fintroller: Fintroller = await deployFintroller(deployer);
  return { fintroller, fyToken, oracle };
}

type UnitFixtureFyTokenReturnType = {
  balanceSheet: MockContract;
  collateral: MockContract;
  fintroller: MockContract;
  fyToken: GodModeFyToken;
  oracle: MockContract;
  redemptionPool: MockContract;
  underlying: MockContract;
};

export async function unitFixtureFyToken(signers: Signer[]): Promise<UnitFixtureFyTokenReturnType> {
  const deployer: Signer = signers[0];

  const oracle: MockContract = await deployStubChainlinkOperator(deployer);
  const fintroller: MockContract = await deployStubFintroller(deployer);
  await fintroller.mock.oracle.returns(oracle.address);

  const balanceSheet: MockContract = await deployStubBalanceSheet(deployer);
  const underlying: MockContract = await deployStubUnderlying(deployer);
  const collateral: MockContract = await deployStubCollateral(deployer);
  const fyToken: GodModeFyToken = await deployGodModeFyToken(
    deployer,
    fyTokenConstants.expirationTime,
    fintroller.address,
    balanceSheet.address,
    underlying.address,
    collateral.address,
  );

  /**
   * The fyToken initializes the Redemption Pool in its constructor, but we don't want
   * it for our unit tests. With help from the god-mode, we override the Redemption Pool
   * with a mock contract.
   */
  const redemptionPool: MockContract = await deployStubRedemptionPool(deployer);
  await fyToken.__godMode__setRedemptionPool(redemptionPool.address);

  return { balanceSheet, collateral, fintroller, oracle, redemptionPool, underlying, fyToken };
}

type UnitFixtureRedemptionPoolReturnType = {
  fintroller: MockContract;
  redemptionPool: GodModeRedemptionPool;
  underlying: MockContract;
  fyToken: MockContract;
};

export async function unitFixtureRedemptionPool(signers: Signer[]): Promise<UnitFixtureRedemptionPoolReturnType> {
  const deployer: Signer = signers[0];

  const fintroller: MockContract = await deployStubFintroller(deployer);
  const underlying: MockContract = await deployStubUnderlying(deployer);

  const fyToken: MockContract = await deployStubFyToken(deployer);
  await fyToken.mock.underlying.returns(underlying.address);
  await fyToken.mock.underlyingPrecisionScalar.returns(One);

  const redemptionPool: GodModeRedemptionPool = await deployGodModeRedemptionPool(
    deployer,
    fintroller.address,
    fyToken.address,
  );
  return { fintroller, redemptionPool, underlying, fyToken };
}
