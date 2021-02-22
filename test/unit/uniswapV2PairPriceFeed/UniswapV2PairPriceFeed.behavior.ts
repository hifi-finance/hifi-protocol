import shouldBehaveLikeUniswapV2PairPriceFeedGetter from "./view/uniswapV2PairPriceFeed";

export function shouldBehaveLikeUniswapV2PairPriceFeed(): void {
  describe("View functions", function () {
    describe("uniswapV2PairPriceFeed", function () {
      shouldBehaveLikeUniswapV2PairPriceFeedGetter();
    });
  });
}
