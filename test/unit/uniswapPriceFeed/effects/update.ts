import chai, { expect } from 'chai';
import { BigNumber } from 'ethers';
import { solidity } from "ethereum-waffle";

chai.use(solidity);

import {
  increaseTime,
} from '../../../jsonRpc';

export default function shouldBehaveLikeUpdate(): void {
  const expectedETHPrice = BigNumber.from('16981803572404270996');
  const expectedUSDPrice = BigNumber.from('2415136177597');

  const windowSize = 240;
  const granularity = 4;
  const periodSize = windowSize / granularity;

  describe('when the timing is right', function() {
    it('updates one time', async function () {
      await this.contracts.uniswapPriceFeed.update();
    });
  });

  describe('when there is not enough data', function() {
    it('reverts', async function () {
      await this.contracts.uniswapPriceFeed.update();
      await expect(this.contracts.uniswapPriceFeed.getLatestETHPrice()).to.be.revertedWith('Missing historical data');
    });
  });

  describe('when there is not enough data (again)', function() {
    it('reverts', async function () {
      for (let i = 0; i < granularity - 1; i += 1) {
        await this.contracts.uniswapPriceFeed.update();
        await increaseTime(BigNumber.from(periodSize));
      }

      await expect(this.contracts.uniswapPriceFeed.getLatestETHPrice()).to.be.revertedWith('Missing historical data');
    });
  });

  describe('when there is enough data', function() {
    it('returns the price in ETH', async function () {
      for (let i = 0; i < granularity; i += 1) {
        await expect(this.contracts.uniswapPriceFeed.update()).to.emit(this.contracts.uniswapPriceFeed, 'PriceUpdated');
        await increaseTime(BigNumber.from(periodSize));
      }

      const ethPrice = await this.contracts.uniswapPriceFeed.getLatestETHPrice();
      expect(ethPrice).to.equal(expectedETHPrice);
    });

    it('returns the price in USD', async function () {
      for (let i = 0; i < granularity; i += 1) {
        await expect(this.contracts.uniswapPriceFeed.update()).to.emit(this.contracts.uniswapPriceFeed, 'PriceUpdated');
        await increaseTime(BigNumber.from(periodSize));
      }

      const usdPrice = await this.contracts.uniswapPriceFeed.getLatestPrice();
      expect(usdPrice).to.equal(expectedUSDPrice);

      const roundData = await this.contracts.uniswapPriceFeed.getRoundData(0);
      expect(roundData.answer).to.equal(expectedUSDPrice);

      const latestRoundData = await this.contracts.uniswapPriceFeed.latestRoundData();
      expect(latestRoundData.answer).to.equal(expectedUSDPrice);
    });
  });

  describe('when there is an unexpected time elapsed', function() {
    it.skip('reverts', async function () {
      await expect(this.contracts.uniswapPriceFeed.getLatestETHPrice()).to.be.revertedWith("Unexpected time elapsed");
    });
  });
}
