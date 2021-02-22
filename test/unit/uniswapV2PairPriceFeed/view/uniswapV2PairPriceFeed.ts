import { expect } from "chai";
import { BigNumber } from "@ethersproject/bignumber";

export default function shouldBehaveLikeUniswapV2PairPriceFeedGetter(): void {
  it("retrives the description", async function () {
    expect(await this.contracts.uniswapV2PairPriceFeed.description()).to.equal("WBTC-UNI/ETH");
  });

  it("retrives the decimals", async function () {
    expect(await this.contracts.uniswapV2PairPriceFeed.decimals()).to.equal(BigNumber.from(8));
  });

  it("retrives the version", async function () {
    expect(await this.contracts.uniswapV2PairPriceFeed.version()).to.equal(BigNumber.from(1));
  });
}
