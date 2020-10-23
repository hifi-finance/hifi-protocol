import { BigNumber } from "@ethersproject/bignumber";
import { Zero } from "@ethersproject/constants";
import { expect } from "chai";

import { BalanceSheetErrors, GenericErrors, OraclePriceUtilsErrors } from "../../../../helpers/errors";
import {
  CollateralConstants,
  Percentages,
  PrecisionScalarForTokenWithEightDecimals,
  TokenAmounts,
  UnderlyingConstants,
} from "../../../../helpers/constants";
import { contextForStubbedCollateralWithEightDecimals } from "../../../../helpers/mochaContexts";

export default function shouldBehaveLikeGetHypotheticalCollateralizationRatio(): void {
  const hypotheticalCollateralizationRatioMantissa: BigNumber = Percentages.OneThousand;
  const lockedCollateral: BigNumber = TokenAmounts.Ten;
  const debt: BigNumber = TokenAmounts.OneHundred;

  describe("when the vault is not open", function () {
    it("reverts", async function () {
      await expect(
        this.contracts.balanceSheet
          .connect(this.signers.borrower)
          .getHypotheticalCollateralizationRatio(
            this.stubs.fyToken.address,
            this.accounts.borrower,
            lockedCollateral,
            debt,
          ),
      ).to.be.revertedWith(GenericErrors.VaultNotOpen);
    });
  });

  describe("when the vault is not open", function () {
    beforeEach(async function () {
      await this.contracts.balanceSheet.connect(this.signers.borrower).openVault(this.stubs.fyToken.address);
    });

    describe("when the locked collateral is zero", function () {
      it("reverts", async function () {
        const zeroCollateralAmount: BigNumber = Zero;
        const hypotheticalCollateralizationRatioMantissa = await this.contracts.balanceSheet.getHypotheticalCollateralizationRatio(
          this.stubs.fyToken.address,
          this.accounts.borrower,
          zeroCollateralAmount,
          debt,
        );
        expect(hypotheticalCollateralizationRatioMantissa).to.equal(Zero);
      });
    });

    describe("when the locked collateral is not zero", function () {
      describe("when the debt is zero", function () {
        it("reverts", async function () {
          const zeroDebt: BigNumber = Zero;
          await expect(
            this.contracts.balanceSheet.getHypotheticalCollateralizationRatio(
              this.stubs.fyToken.address,
              this.accounts.borrower,
              lockedCollateral,
              zeroDebt,
            ),
          ).to.be.revertedWith(BalanceSheetErrors.GetHypotheticalCollateralizationRatioDebtZero);
        });
      });

      describe("when the debt is not zero", function () {
        describe("when the collateral price from the oracle is zero", function () {
          beforeEach(async function () {
            const zeroCollateralPrice: BigNumber = Zero;
            await this.stubs.oracle.mock.price.withArgs(CollateralConstants.EtherSymbol).returns(zeroCollateralPrice);
          });

          it("reverts", async function () {
            await expect(
              this.contracts.balanceSheet.getHypotheticalCollateralizationRatio(
                this.stubs.fyToken.address,
                this.accounts.borrower,
                lockedCollateral,
                debt,
              ),
            ).to.be.revertedWith(OraclePriceUtilsErrors.PriceZero);
          });
        });

        describe("when the collateral price from the oracle is not zero", function () {
          describe("when the underlying price from the oracle is zero", function () {
            beforeEach(async function () {
              const zeroUnderlyingPrice: BigNumber = Zero;
              await this.stubs.oracle.mock.price.withArgs(UnderlyingConstants.Symbol).returns(zeroUnderlyingPrice);
            });

            it("reverts", async function () {
              await expect(
                this.contracts.balanceSheet.getHypotheticalCollateralizationRatio(
                  this.stubs.fyToken.address,
                  this.accounts.borrower,
                  lockedCollateral,
                  debt,
                ),
              ).to.be.revertedWith(OraclePriceUtilsErrors.PriceZero);
            });
          });

          describe("when the collateral price from the oracle is not zero", function () {
            contextForStubbedCollateralWithEightDecimals("when the collateral has 6 decimals", function () {
              it("retrieves the hypothetical collateralization ratio mantissa", async function () {
                const downscaledLockedCollateral = lockedCollateral.div(PrecisionScalarForTokenWithEightDecimals);
                const contractHypotheticalCollateralizationRatioMantissa: BigNumber = await this.contracts.balanceSheet.getHypotheticalCollateralizationRatio(
                  this.stubs.fyToken.address,
                  this.accounts.borrower,
                  downscaledLockedCollateral,
                  debt,
                );
                expect(contractHypotheticalCollateralizationRatioMantissa).to.equal(
                  hypotheticalCollateralizationRatioMantissa,
                );
              });
            });

            describe("when the collateral has 18 decimals", function () {
              it("retrieves the hypothetical collateralization ratio mantissa", async function () {
                const contractHypotheticalCollateralizationRatioMantissa: BigNumber = await this.contracts.balanceSheet.getHypotheticalCollateralizationRatio(
                  this.stubs.fyToken.address,
                  this.accounts.borrower,
                  lockedCollateral,
                  debt,
                );
                expect(contractHypotheticalCollateralizationRatioMantissa).to.equal(
                  hypotheticalCollateralizationRatioMantissa,
                );
              });
            });
          });
        });
      });
    });
  });
}
