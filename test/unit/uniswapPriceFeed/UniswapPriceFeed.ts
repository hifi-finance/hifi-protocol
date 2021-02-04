import { shouldBehaveLikeUniswapPriceFeed } from './UniswapPriceFeed.behavior';
import { unitFixtureUniswapPriceFeed } from '../fixtures';

export function unitTestUniswapPriceFeed(): void {
  describe("UniswapPriceFeed", function () {
    beforeEach(async function () {
      const { uniswapPriceFeed } = await this.loadFixture(unitFixtureUniswapPriceFeed);
      this.contracts.uniswapPriceFeed = uniswapPriceFeed;
    });

    shouldBehaveLikeUniswapPriceFeed();
  });
}
