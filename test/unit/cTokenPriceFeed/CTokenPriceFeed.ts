import { shouldBehaveLikeCTokenPriceFeed } from "./CTokenPriceFeed.behavior";
import { unitFixtureCTokenPriceFeed } from "../fixtures";

export function unitTestCTokenPriceFeed(): void {
  describe("CTokenPriceFeed", function () {
    beforeEach(async function () {
      const {
        cToken,
        cTokenPriceFeed,
        collateralPriceFeed,
      } = await this.loadFixture(
        unitFixtureCTokenPriceFeed,
      );

      this.contracts.cTokenPriceFeed = cTokenPriceFeed;
      this.stubs.cToken = cToken;
      this.stubs.collateralPriceFeed = collateralPriceFeed;
    });

    shouldBehaveLikeCTokenPriceFeed();
  });
}
