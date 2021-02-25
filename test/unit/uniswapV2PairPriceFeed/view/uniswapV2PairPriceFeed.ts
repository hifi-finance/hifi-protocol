import { expect } from "chai";
import { BigNumber } from "@ethersproject/bignumber";
import { UniswapV2PairPriceFeedErrors } from "../../../../helpers/errors";
import { stubUniswapV2Pair } from "../../stubs";

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

    await stubUniswapV2Pair.call(this, totalSupplyGiven, reserve0Given, reserve1Given, price0Given, price1Given);

    const latestRoundData = await this.contracts.uniswapV2PairPriceFeed.latestRoundData();

    expect(latestRoundData.answer).to.equal(priceExpected);
  });

  describe("reverts on math errors", function () {
    it("p0*p1 overflow", async function () {
      const totalSupplyGiven = BigNumber.from("201971551515601793370");
      const reserve0Given = BigNumber.from("1121516254214");
      const reserve1Given = BigNumber.from("7819315255132");
      const price0Given = BigNumber.from("521357125224413235352135712213352244135443521357125222441353135712522441353");
      const price1Given = BigNumber.from("161123354533551561611233545312343551561226112332345453355156233545335515621");

      await stubUniswapV2Pair.call(this, totalSupplyGiven, reserve0Given, reserve1Given, price0Given, price1Given);

      await expect(this.contracts.uniswapV2PairPriceFeed.latestRoundData()).to.be.revertedWith(
        UniswapV2PairPriceFeedErrors.LatestRoundDataMathError,
      );
    });

    it("sqrt(r0*r1)*sqrt(p0*p1) overflow", async function () {
      const totalSupplyGiven = BigNumber.from("201971551515601793370");
      const reserve0Given = BigNumber.from("1121516254214");
      const reserve1Given = BigNumber.from("7819315255132");
      const price0Given = BigNumber.from("521357125224413535213571252244135352135712522441353");
      const price1Given = BigNumber.from("161123354533551561611233545335515616112335453355156");

      await stubUniswapV2Pair.call(this, totalSupplyGiven, reserve0Given, reserve1Given, price0Given, price1Given);

      await expect(this.contracts.uniswapV2PairPriceFeed.latestRoundData()).to.be.revertedWith(
        UniswapV2PairPriceFeedErrors.LatestRoundDataMathError,
      );
    });

    it("2*sqrt(r0*r1)*sqrt(p0*p1) overflow", async function () {
      const totalSupplyGiven = BigNumber.from("201971551515601793370");
      const reserve0Given = BigNumber.from("1121516254214");
      const reserve1Given = BigNumber.from("7819315255132");
      const price0Given = BigNumber.from("5213571252244135352135712522441353521357125224413");
      const price1Given = BigNumber.from("1611233545335515616112335453355156161123354533551");

      await stubUniswapV2Pair.call(this, totalSupplyGiven, reserve0Given, reserve1Given, price0Given, price1Given);

      await expect(this.contracts.uniswapV2PairPriceFeed.latestRoundData()).to.be.revertedWith(
        UniswapV2PairPriceFeedErrors.LatestRoundDataMathError,
      );
    });
  });
}
