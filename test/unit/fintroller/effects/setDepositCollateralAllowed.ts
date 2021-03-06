import { expect } from "chai";

import { AdminErrors, GenericErrors } from "../../../../helpers/errors";

export default function shouldBehaveLikeSetDepositCollateralAllowed(): void {
  describe("when the caller is not the admin", function () {
    it("reverts", async function () {
      await expect(
        this.contracts.fintroller
          .connect(this.signers.raider)
          .setDepositCollateralAllowed(this.stubs.fyToken.address, true),
      ).to.be.revertedWith(AdminErrors.NotAdmin);
    });
  });

  describe("when the caller is the admin", function () {
    describe("when the bond is not listed", function () {
      it("rejects", async function () {
        await expect(
          this.contracts.fintroller
            .connect(this.signers.admin)
            .setDepositCollateralAllowed(this.stubs.fyToken.address, true),
        ).to.be.revertedWith(GenericErrors.BondNotListed);
      });
    });

    describe("when the bond is listed", function () {
      beforeEach(async function () {
        await this.contracts.fintroller.connect(this.signers.admin).listBond(this.stubs.fyToken.address);
      });

      it("sets the value to true", async function () {
        await this.contracts.fintroller
          .connect(this.signers.admin)
          .setDepositCollateralAllowed(this.stubs.fyToken.address, true);
        const newState: boolean = await this.contracts.fintroller.getDepositCollateralAllowed(
          this.stubs.fyToken.address,
        );
        expect(newState).to.equal(true);
      });

      it("sets the value to false", async function () {
        await this.contracts.fintroller
          .connect(this.signers.admin)
          .setDepositCollateralAllowed(this.stubs.fyToken.address, false);
        const newState: boolean = await this.contracts.fintroller.getDepositCollateralAllowed(
          this.stubs.fyToken.address,
        );
        expect(newState).to.equal(false);
      });

      it("emits a SetDepositCollateralAllowed event", async function () {
        await expect(
          this.contracts.fintroller
            .connect(this.signers.admin)
            .setDepositCollateralAllowed(this.stubs.fyToken.address, true),
        )
          .to.emit(this.contracts.fintroller, "SetDepositCollateralAllowed")
          .withArgs(this.signers.admin.address, this.stubs.fyToken.address, true);
      });
    });
  });
}
