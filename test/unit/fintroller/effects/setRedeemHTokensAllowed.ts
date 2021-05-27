import { expect } from "chai";

import { AdminErrors, GenericErrors } from "../../../../helpers/errors";

export default function shouldBehaveLikeSetRedeemHTokensAllowed(): void {
  context("when the caller is not the admin", function () {
    it("reverts", async function () {
      await expect(
        this.contracts.fintroller.connect(this.signers.raider).setRedeemHTokensAllowed(this.stubs.hToken.address, true),
      ).to.be.revertedWith(AdminErrors.NotAdmin);
    });
  });

  context("when the caller is the admin", function () {
    context("when the bond is not listed", function () {
      it("rejects", async function () {
        await expect(
          this.contracts.fintroller
            .connect(this.signers.admin)
            .setRedeemHTokensAllowed(this.stubs.hToken.address, true),
        ).to.be.revertedWith(GenericErrors.BondNotListed);
      });
    });

    context("when the bond is listed", function () {
      beforeEach(async function () {
        await this.contracts.fintroller.connect(this.signers.admin).listBond(this.stubs.hToken.address);
      });

      it("sets the value to true", async function () {
        await this.contracts.fintroller
          .connect(this.signers.admin)
          .setRedeemHTokensAllowed(this.stubs.hToken.address, true);
        const newState: boolean = await this.contracts.fintroller.getRedeemHTokensAllowed(this.stubs.hToken.address);
        expect(newState).to.equal(true);
      });

      it("sets the value to false", async function () {
        await this.contracts.fintroller
          .connect(this.signers.admin)
          .setRedeemHTokensAllowed(this.stubs.hToken.address, false);
        const newState: boolean = await this.contracts.fintroller.getRedeemHTokensAllowed(this.stubs.hToken.address);
        expect(newState).to.equal(false);
      });

      it("emits a SetRedeemHTokensAllowed event", async function () {
        await expect(
          this.contracts.fintroller
            .connect(this.signers.admin)
            .setRedeemHTokensAllowed(this.stubs.hToken.address, true),
        )
          .to.emit(this.contracts.fintroller, "SetRedeemHTokensAllowed")
          .withArgs(this.signers.admin.address, this.stubs.hToken.address, true);
      });
    });
  });
}