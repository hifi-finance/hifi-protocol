import { BigNumber } from "@ethersproject/bignumber";
import { One, Zero } from "@ethersproject/constants";
import { expect } from "chai";

import { fintrollerConstants, percentages } from "../../../../helpers/constants";
import { AdminErrors, FintrollerErrors, GenericErrors } from "../../../../helpers/errors";

export default function shouldBehaveLikeSetBondLiquidationIncentive(): void {
  const newLiquidationIncentive: BigNumber = percentages.oneHundredAndTwenty;
  const overflowLiquidationIncentive: BigNumber = fintrollerConstants.liquidationIncentiveUpperBoundMantissa.add(One);
  const underflowLiquidationIncentive: BigNumber = fintrollerConstants.liquidationIncentiveLowerBoundMantissa.sub(One);

  describe("when the caller is not the admin", function () {
    it("reverts", async function () {
      await expect(
        this.contracts.fintroller
          .connect(this.signers.raider)
          .setBondLiquidationIncentive(this.stubs.fyToken.address, newLiquidationIncentive),
      ).to.be.revertedWith(AdminErrors.NotAdmin);
    });
  });

  describe("when the caller is the admin", function () {
    describe("when the bond is not listed", function () {
      it("reverts", async function () {
        await expect(
          this.contracts.fintroller
            .connect(this.signers.admin)
            .setBondLiquidationIncentive(this.stubs.fyToken.address, newLiquidationIncentive),
        ).to.be.revertedWith(GenericErrors.BondNotListed);
      });
    });

    describe("when the bond is listed", function () {
      beforeEach(async function () {
        await this.contracts.fintroller.connect(this.signers.admin).listBond(this.stubs.fyToken.address);
      });

      describe("when the liquidation incentive is not valid", function () {
        describe("when the liquidation ratio is zero", function () {
          it("reverts", async function () {
            await expect(
              this.contracts.fintroller
                .connect(this.signers.admin)
                .setBondLiquidationIncentive(this.stubs.fyToken.address, Zero),
            ).to.be.revertedWith(FintrollerErrors.SetBondLiquidationIncentiveLowerBound);
          });
        });

        describe("when the liquidation incentive is higher than 150%", function () {
          it("reverts", async function () {
            await expect(
              this.contracts.fintroller
                .connect(this.signers.admin)
                .setBondLiquidationIncentive(this.stubs.fyToken.address, overflowLiquidationIncentive),
            ).to.be.revertedWith(FintrollerErrors.SetBondLiquidationIncentiveUpperBound);
          });
        });

        describe("when the liquidation incentive is lower than 100%", function () {
          it("reverts", async function () {
            await expect(
              this.contracts.fintroller
                .connect(this.signers.admin)
                .setBondLiquidationIncentive(this.stubs.fyToken.address, underflowLiquidationIncentive),
            ).to.be.revertedWith(FintrollerErrors.SetBondLiquidationIncentiveLowerBound);
          });
        });
      });

      describe("when the liquidation incentive is valid", function () {
        it("sets the new liquidation incentive", async function () {
          await this.contracts.fintroller
            .connect(this.signers.admin)
            .setBondLiquidationIncentive(this.stubs.fyToken.address, newLiquidationIncentive);
          const liquidationIncentive: BigNumber = await this.contracts.fintroller.getBondLiquidationIncentive(
            this.stubs.fyToken.address,
          );
          expect(liquidationIncentive).to.equal(newLiquidationIncentive);
        });

        it("emits a SetBondLiquidationIncentive event", async function () {
          await expect(
            this.contracts.fintroller
              .connect(this.signers.admin)
              .setBondLiquidationIncentive(this.stubs.fyToken.address, newLiquidationIncentive),
          )
            .to.emit(this.contracts.fintroller, "SetBondLiquidationIncentive")
            .withArgs(
              this.signers.admin.address,
              this.stubs.fyToken.address,
              fintrollerConstants.defaultLiquidationIncentive,
              newLiquidationIncentive,
            );
        });
      });
    });
  });
}
