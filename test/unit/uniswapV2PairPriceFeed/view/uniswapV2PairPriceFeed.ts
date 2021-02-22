import { expect } from "chai";
import { BigNumber } from "@ethersproject/bignumber";
import { Zero } from "@ethersproject/constants";

export default function shouldBehaveLikeUniswapV2PairPriceFeedGetter(): void {
  it("returns the description", async function () {
    expect(await this.contracts.uniswapV2PairPriceFeed.description()).to.equal("WBTC-UNI/USD");
  });

  it("returns the decimals", async function () {
    expect(await this.contracts.uniswapV2PairPriceFeed.decimals()).to.equal(BigNumber.from(8));
  });

  it("returns the version", async function () {
    expect(await this.contracts.uniswapV2PairPriceFeed.version()).to.equal(BigNumber.from(1));
  });

  it("returns the correct LP token price", async function () {
    const totalSupplyGiven = BigNumber.from("201971551515601793370");
    const reserve0Given = BigNumber.from("1121516254214");
    const reserve1Given = BigNumber.from("7819315255132");
    const price0Given = BigNumber.from("52135712522441353");
    const price1Given = BigNumber.from("16112335453355156");

    const priceExpected = BigNumber.from(
      Math.trunc(
        (2 * Math.sqrt(Number(reserve0Given.mul(reserve1Given))) * Math.sqrt(Number(price0Given.mul(price1Given)))) /
          Number(totalSupplyGiven),
      ) + "",
    );

    await this.stubs.uniswapV2Pair.mock.totalSupply.returns(totalSupplyGiven);
    await this.stubs.uniswapV2Pair.mock.getReserves.returns(reserve0Given, reserve1Given, 0);
    await this.stubs.underlyingOracles[0].mock.latestRoundData.returns(Zero, price0Given, Zero, Zero, Zero);
    await this.stubs.underlyingOracles[1].mock.latestRoundData.returns(Zero, price1Given, Zero, Zero, Zero);

    const latestRoundData = await this.contracts.uniswapV2PairPriceFeed.latestRoundData();

    expect(latestRoundData.answer).to.equal(priceExpected);
  });
}
