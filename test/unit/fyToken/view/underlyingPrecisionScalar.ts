import { BigNumber } from "@ethersproject/bignumber";
import { expect } from "chai";

import { fyTokenConstants, precisionScalars } from "../../../../helpers/constants";
import { FyToken } from "../../../../typechain/FyToken";
import { deployFyToken } from "../../../deployers";

export default function shouldBehaveLikeUnderlyingPrecisionScalarGetter(): void {
  describe("when the underlying has 6 decimals", function () {
    beforeEach(async function () {
      await this.stubs.underlying.mock.decimals.returns(BigNumber.from(6));
    });

    it("retrieves 1", async function () {
      const fyToken: FyToken = await deployFyToken(
        this.signers.admin,
        fyTokenConstants.expirationTime,
        this.stubs.fintroller.address,
        this.stubs.balanceSheet.address,
        this.stubs.underlying.address,
        this.stubs.collateral.address,
      );
      const underlyingPrecisionScalar: BigNumber = await fyToken.underlyingPrecisionScalar();
      expect(underlyingPrecisionScalar).to.equal(precisionScalars.tokenWith6Decimals);
    });
  });

  describe("when the underlying has 8 decimals", function () {
    beforeEach(async function () {
      await this.stubs.underlying.mock.decimals.returns(BigNumber.from(8));
    });

    it("retrieves 1.0e10", async function () {
      const fyToken: FyToken = await deployFyToken(
        this.signers.admin,
        fyTokenConstants.expirationTime,
        this.stubs.fintroller.address,
        this.stubs.balanceSheet.address,
        this.stubs.underlying.address,
        this.stubs.collateral.address,
      );
      const underlyingPrecisionScalar: BigNumber = await fyToken.underlyingPrecisionScalar();
      expect(underlyingPrecisionScalar).to.equal(precisionScalars.tokenWith8Decimals);
    });
  });

  describe("when the underlying has 18 decimals", function () {
    beforeEach(async function () {
      await this.stubs.underlying.mock.decimals.returns(BigNumber.from(18));
    });

    it("retrieves 1", async function () {
      const fyToken: FyToken = await deployFyToken(
        this.signers.admin,
        fyTokenConstants.expirationTime,
        this.stubs.fintroller.address,
        this.stubs.balanceSheet.address,
        this.stubs.underlying.address,
        this.stubs.collateral.address,
      );
      const underlyingPrecisionScalar: BigNumber = await fyToken.underlyingPrecisionScalar();
      expect(underlyingPrecisionScalar).to.equal(precisionScalars.tokenWith18Decimals);
    });
  });
}
