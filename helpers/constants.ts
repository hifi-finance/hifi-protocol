import { BigNumber } from "@ethersproject/bignumber";
import fp from "evm-fp";

import { getDaysInSeconds, getNow } from "./time";

// Ethereum constants.
export const addressOne: string = "0x0000000000000000000000000000000000000001";
export const maxInt256: BigNumber = BigNumber.from(
  "57896044618658097711785492504343953926634992332820282019728792003956564819967",
);

// Generic amounts.
export const ten: BigNumber = fp("1e-17");
export const tenMillion: BigNumber = fp("0.0000001");
export const fiftyMillion: BigNumber = fp("0.0000050");

// Decimals.
export const defaultNumberOfDecimals: BigNumber = fp("1.8e-17");
export const chainlinkPricePrecision: BigNumber = fp("8e-18");
export const chainlinkPricePrecisionScalar: BigNumber = fp("1e-8");

// Percentages as mantissas (decimal scalars with 18 decimals).
export const percentages: { [name: string]: BigNumber } = {
  oneHundred: fp("1"),
  oneHundredAndTen: fp("1.1"),
  oneHundredAndTwenty: fp("1.2"),
  oneHundredAndFifty: fp("1.5"),
  oneHundredAndSeventyFive: fp("1.75"),
  oneThousand: fp("10"),
  tenThousand: fp("100"),
};

// Ten raised to the difference between 18 and the token's decimals.
export const precisionScalars = {
  tokenWith6Decimals: fp("1e-6"),
  tokenWith8Decimals: fp("1e-8"),
  tokenWith18Decimals: fp("1e-18"),
};

// Prices with 8 decimals, as per Chainlink format.
export const prices: { [name: string]: BigNumber } = {
  oneDollar: fp("1e-10"),
  twelveDollars: fp("1.2e-9"),
  oneHundredDollars: fp("1e-8"),
};

// These amounts assume that the token has 18 decimals.
export const tokenAmounts: { [name: string]: BigNumber } = {
  pointFiftyFive: fp("0.55"),
  one: fp("1"),
  two: fp("2"),
  ten: fp("10"),
  forty: fp("40"),
  fifty: fp("50"),
  oneHundred: fp("100"),
  oneThousand: fp("1000"),
  tenThousand: fp("10000"),
  oneHundredThousand: fp("100000"),
  oneMillion: fp("1000000"),
};

// Chain ids.
export const chainIds = {
  hardhat: 31337,
  goerli: 5,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3,
};

// Gas limits, needed lest deployments fail on coverage.
export const gasLimits = {
  hardhat: {
    blockGasLimit: tenMillion,
    callGasLimit: tenMillion,
    deployContractGasLimit: tenMillion,
  },
  coverage: {
    blockGasLimit: fiftyMillion,
    callGasLimit: fiftyMillion,
    deployContractGasLimit: fiftyMillion,
  },
};

// Private keys.
export const defaultPrivateKeys = {
  admin: "0x907eb204083c9b1c24fdfc26bb120a8713fcc3323edf1b8423a2ad58d0fbaeb8",
  borrower: "0xd0792a518700b34f3cf29d533f1d8bb81262eabca4f1817212a5044ee866c3a6",
  lender: "0xc0152f90ad35f85568c66192307be596aaa3431cb23dda6d99e7393b959b0930",
  liquidator: "0x2630b870626d4f8d344cb7a3eb9f775a66b19a8a00779a30bb401739a4c9ec6b",
  maker: "0x6a9bff3d641bc1311f1f67d58440c76acaa81a273d287aeb6af96950ad59df65",
  raider: "0x638b667580ca2334d72ed39f20c802b7a07cd0614a9a43c64f91d8058cfe884b",
};

// Contract-specific constants
export const balanceSheetConstants = {
  defaultVault: {
    debt: fp("0"),
    freeCollateral: fp("0"),
    lockedCollateral: fp("0"),
    isOpen: true,
  },
};

export const fintrollerConstants = {
  collateralizationRatioLowerBoundMantissa: percentages.oneHundred,
  collateralizationRatioUpperBoundMantissa: percentages.tenThousand,
  defaultCollateralizationRatio: percentages.oneHundredAndFifty,
  defaultLiquidationIncentive: percentages.oneHundredAndTen,
  liquidationIncentiveLowerBoundMantissa: percentages.oneHundred,
  liquidationIncentiveUpperBoundMantissa: percentages.oneHundredAndFifty,
  oraclePrecisionScalar: chainlinkPricePrecisionScalar,
};

// TODO: make the name and symbol match the expiration time
export const fyTokenConstants = {
  decimals: defaultNumberOfDecimals,
  expirationTime: getNow().add(getDaysInSeconds(90)),
  name: "hfyUSDC (2022-01-01)",
  symbol: "hfyUSDC-JAN22",
};

export const underlyingConstants = {
  decimals: 6,
  name: "USD Coin",
  symbol: "USDC",
};
