import { baseContext } from "../contexts";

import { unitTestBalanceSheet } from "./balanceSheet/BalanceSheet";
import { unitTestChainlinkOperator } from "./chainlinkOperator/ChainlinkOperator";
import { unitTestFintroller } from "./fintroller/Fintroller";
import { unitTestFyToken } from "./fyToken/FyToken";
import { unitTestRedemptionPool } from "./redemptionPool/RedemptionPool";
import { unitTestCTokenPriceFeed } from "./cTokenPriceFeed/CTokenPriceFeed";

baseContext("Unit Tests", function () {
  /*unitTestBalanceSheet();
  unitTestChainlinkOperator();
  unitTestFintroller();
  unitTestFyToken();
  unitTestRedemptionPool();*/
  unitTestCTokenPriceFeed();
});
