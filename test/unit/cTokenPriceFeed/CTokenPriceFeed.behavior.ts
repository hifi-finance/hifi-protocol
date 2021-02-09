import shouldBehaveLikeCTokenPriceFeedGetter from "./view/cTokenPriceFeed";

export function shouldBehaveLikeCTokenPriceFeed(): void {
  describe("View functions", function () {
    describe("cTokenPriceFeed", function () {
      shouldBehaveLikeCTokenPriceFeedGetter();
    });
  });
}
