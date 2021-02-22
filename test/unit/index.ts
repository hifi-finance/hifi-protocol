import { baseContext } from "../contexts";

import { unitTestBalanceSheet } from "./balanceSheet/BalanceSheet";
import { unitTestChainlinkOperator } from "./chainlinkOperator/ChainlinkOperator";
import { unitTestFintroller } from "./fintroller/Fintroller";
import { unitTestFyToken } from "./fyToken/FyToken";
import { unitTestRedemptionPool } from "./redemptionPool/RedemptionPool";
import { unitTestUniswapV2PairPriceFeed } from "./uniswapV2PairPriceFeed/UniswapV2PairPriceFeed";

baseContext("Unit Tests", function () {
  unitTestBalanceSheet();
  unitTestChainlinkOperator();
  unitTestFintroller();
  unitTestFyToken();
  unitTestRedemptionPool();
  unitTestUniswapV2PairPriceFeed();
});
