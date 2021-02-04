import { expect } from 'chai';

export default function shouldBehaveLikeGetStuff(): void {
  const windowSize = 240;
  const granularity = 4;
  const periodSize = windowSize / granularity;

  describe('when everything is set', function () {
    it('gets the decimals', async function () {
      const decimals = await this.contracts.uniswapPriceFeed.decimals();
      expect(decimals).to.equal(8);
    });

    it('gets the description', async function () {
      const description = await this.contracts.uniswapPriceFeed.description();
      expect(description).to.equal('SOCKS/USD');
    });

    it('gets the window size', async function () {
      const windowSizeRes = await this.contracts.uniswapPriceFeed.windowSize();
      expect(windowSizeRes).to.equal(windowSize);
    });

    it('gets the granularity', async function () {
      const granularityRes = await this.contracts.uniswapPriceFeed.granularity();
      expect(granularityRes).to.equal(granularity);
    });

    it('gets the period size', async function () {
      const periodSizeRes = await this.contracts.uniswapPriceFeed.periodSize();
      expect(periodSizeRes).to.equal(periodSize);
    });
  });
}
