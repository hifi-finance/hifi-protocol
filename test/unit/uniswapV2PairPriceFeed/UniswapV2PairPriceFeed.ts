import { shouldBehaveLikeUniswapV2PairPriceFeed } from "./UniswapV2PairPriceFeed.behavior";
import { unitFixtureUniswapV2PairPriceFeed } from "../fixtures";

export function unitTestUniswapV2PairPriceFeed(): void {
  describe("UniswapV2Pair", function () {
    beforeEach(async function () {
      const { uniswapV2PairPriceFeed, uniswapV2Pair, underlyingOracles } = await this.loadFixture(
        unitFixtureUniswapV2PairPriceFeed,
      );
      this.contracts.uniswapV2PairPriceFeed = uniswapV2PairPriceFeed;
      this.stubs.uniswapV2Pair = uniswapV2Pair;
      this.stubs.underlyingOracles = underlyingOracles;
    });

    shouldBehaveLikeUniswapV2PairPriceFeed();
  });
}
