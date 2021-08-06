import { BigNumber } from "@ethersproject/bignumber";
import { Zero } from "@ethersproject/constants";
import { expect } from "chai";

import {
  DEFAULT_LIQUIDATION_INCENTIVE,
  LIQUIDATION_INCENTIVE_LOWER_BOUND,
  NORMALIZED_WBTC_PRICE,
} from "../../../../helpers/constants";
import { bn, hUSDC } from "../../../../helpers/numbers";
import { getSeizableCollateralAmount } from "../../../shared/mirrors";

export default function shouldBehaveLikeGetSeizableCollateralAmount(): void {
  context("when the liquidation incentive is 100%", function () {
    beforeEach(async function () {
      await this.mocks.fintroller.mock.getLiquidationIncentive
        .withArgs(this.mocks.wbtc.address)
        .returns(LIQUIDATION_INCENTIVE_LOWER_BOUND);
    });

    it("returns zero", async function () {
      const repayAmount: BigNumber = hUSDC("15000");
      const seizableCollateralAmount: BigNumber = await this.contracts.balanceSheet.getSeizableCollateralAmount(
        this.mocks.hTokens[0].address,
        repayAmount,
        this.mocks.wbtc.address,
      );
      expect(seizableCollateralAmount).to.equal(Zero);
    });
  });

  context("when the liquidation incentive is not 100%", function () {
    beforeEach(async function () {
      await this.mocks.fintroller.mock.getLiquidationIncentive
        .withArgs(this.mocks.wbtc.address)
        .returns(DEFAULT_LIQUIDATION_INCENTIVE);
    });

    context("when the repay amount is zero", function () {
      it("returns zero", async function () {
        const repayAmount: BigNumber = hUSDC("0");
        const seizableCollateralAmount: BigNumber = await this.contracts.balanceSheet.getSeizableCollateralAmount(
          this.mocks.hTokens[0].address,
          repayAmount,
          this.mocks.wbtc.address,
        );
        expect(seizableCollateralAmount).to.equal(Zero);
      });
    });

    context("when the repay amount is not zero", function () {
      const repayAmount: BigNumber = hUSDC("15000");

      context("when the collateral has 18 decimals", function () {
        const collateralDecimals: BigNumber = bn("18");

        beforeEach(async function () {
          await this.mocks.wbtc.mock.decimals.returns(collateralDecimals);
        });

        it("retrieves the correct value", async function () {
          const seizableCollateralAmount: BigNumber = await this.contracts.balanceSheet.getSeizableCollateralAmount(
            this.mocks.hTokens[0].address,
            repayAmount,
            this.mocks.wbtc.address,
          );
          expect(seizableCollateralAmount).to.equal(
            getSeizableCollateralAmount(repayAmount, NORMALIZED_WBTC_PRICE, collateralDecimals),
          );
        });
      });

      context("when the collateral has 8 decimals", function () {
        const collateralDecimals: BigNumber = bn("8");

        beforeEach(async function () {
          await this.mocks.wbtc.mock.decimals.returns(collateralDecimals);
        });

        it("retrieves the correct value", async function () {
          const seizableCollateralAmount: BigNumber = await this.contracts.balanceSheet.getSeizableCollateralAmount(
            this.mocks.hTokens[0].address,
            repayAmount,
            this.mocks.wbtc.address,
          );
          expect(seizableCollateralAmount).to.equal(
            getSeizableCollateralAmount(repayAmount, NORMALIZED_WBTC_PRICE, collateralDecimals),
          );
        });
      });
    });
  });
}
