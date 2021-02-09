import { expect } from "chai";
import { BigNumber } from "@ethersproject/bignumber";
import { Zero } from '@ethersproject/constants';

export default function shouldBehaveLikeCTokenPriceFeedGetter(): void {
  it("retrives the description", async function () {
    expect(await this.contracts.cTokenPriceFeed.description()).to.equal("cWBTC/USD");
  });

  it("retrives the decimals", async function () {
    expect(await this.contracts.cTokenPriceFeed.decimals()).to.equal(BigNumber.from(8));
  });

  it("retrives the version", async function () {
    expect(await this.contracts.cTokenPriceFeed.version()).to.equal(BigNumber.from(1));
  });

  it("retrives the exchange rate stored from the cToken", async function () {
    const exchangeRateStored = BigNumber.from("20197159760179370");
    const collateralUSDPrice = BigNumber.from("4578501558154");
    const expectedCTokenUSDPrice = exchangeRateStored.mul(collateralUSDPrice).div(BigNumber.from('1000000000000000000'))

    await this.stubs.cToken.mock.exchangeRateStored.returns(exchangeRateStored);
    await this.stubs.collateralPriceFeed.mock.latestRoundData.returns(
      Zero,
      collateralUSDPrice,
      Zero,
      Zero,
      Zero,
    );

    const latestRoundData = await this.contracts.cTokenPriceFeed.latestRoundData();
    expect(latestRoundData[1]).to.equal(expectedCTokenUSDPrice);
  });
}
