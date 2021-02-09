/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "@paulrberg/contracts/access/Admin.sol";
import "@paulrberg/contracts/math/CarefulMath.sol";
import "@paulrberg/contracts/token/erc20/Erc20Interface.sol";
import "@paulrberg/contracts/token/erc20/Erc20Recover.sol";
import "@paulrberg/contracts/token/erc20/SafeErc20.sol";
import "@paulrberg/contracts/utils/ReentrancyGuard.sol";

import "./FintrollerInterface.sol";
import "./RedemptionPoolInterface.sol";
import "./external/balancer/BFactoryInterface.sol";

/**
 * @title RedemptionPool
 * @author Hifi
 * @notice Mints 1 fyToken in exhchange for 1 underlying before maturation and burns 1 fyToken
 * in exchange for 1 underlying after maturation.
 * @dev Instantiated by the fyToken in its constructor.
 */
contract RedemptionPool is
    CarefulMath, /* no dependency */
    ReentrancyGuard, /* no dependency */
    RedemptionPoolInterface, /* one dependency */
    Admin, /* two dependencies */
    Erc20Recover /* five dependencies */
{
    using SafeErc20 for Erc20Interface;

    /**
     * @param fintroller_ The address of the Fintroller contract.
     * @param fyToken_ The address of the fyToken contract.
     */
    constructor(FintrollerInterface fintroller_, FyTokenInterface fyToken_) Admin() {
        /* Set the Fintroller contract and sanity check it. */
        fintroller = fintroller_;
        fintroller.isFintroller();

        /**
         * Set the fyToken contract. It cannot be sanity-checked because the fyToken creates this
         * contract in its own constructor and contracts cannot be called while initializing.
         */
        fyToken = fyToken_;
    }

    struct RedeemFyTokensLocalVars {
        MathError mathErr;
        uint256 newUnderlyingTotalSupply;
        uint256 underlyingPrecisionScalar;
        uint256 underlyingAmount;
    }

    /**
     * @notice Pays the token holder the face value at maturation time.
     *
     * @dev Emits a {RedeemFyTokens} event.
     *
     * Requirements:
     *
     * - Must be called after maturation.
     * - The amount to redeem cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - There must be enough liquidity in the Redemption Pool.
     *
     * @param fyTokenAmount The amount of fyTokens to redeem for the underlying asset.
     * @return true = success, otherwise it reverts.
     */
    function redeemFyTokens(uint256 fyTokenAmount) external override nonReentrant returns (bool) {
        RedeemFyTokensLocalVars memory vars;

        /* Checks: maturation time. */
        require(block.timestamp >= fyToken.expirationTime(), "ERR_BOND_NOT_MATURED");

        /* Checks: the zero edge case. */
        require(fyTokenAmount > 0, "ERR_REDEEM_FYTOKENS_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        require(fintroller.getRedeemFyTokensAllowed(fyToken), "ERR_REDEEM_FYTOKENS_NOT_ALLOWED");

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be downscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        if (vars.underlyingPrecisionScalar != 1) {
            (vars.mathErr, vars.underlyingAmount) = divUInt(fyTokenAmount, vars.underlyingPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_REDEEM_FYTOKENS_MATH_ERROR");
        } else {
            vars.underlyingAmount = fyTokenAmount;
        }

        /* Checks: there is enough liquidity. */
        require(vars.underlyingAmount <= totalUnderlyingSupply, "ERR_REDEEM_FYTOKENS_INSUFFICIENT_UNDERLYING");

        /* Effects: decrease the remaining supply of underlying. */
        (vars.mathErr, vars.newUnderlyingTotalSupply) = subUInt(totalUnderlyingSupply, vars.underlyingAmount);
        assert(vars.mathErr == MathError.NO_ERROR);
        totalUnderlyingSupply = vars.newUnderlyingTotalSupply;

        /* Interactions: burn the fyTokens. */
        require(fyToken.burn(msg.sender, fyTokenAmount), "ERR_SUPPLY_UNDERLYING_CALL_BURN");

        /* Interactions: perform the Erc20 transfer. */
        fyToken.underlying().safeTransfer(msg.sender, vars.underlyingAmount);

        emit RedeemFyTokens(msg.sender, fyTokenAmount, vars.underlyingAmount);

        return true;
    }

    struct SupplyUnderlyingLocalVars {
        MathError mathErr;
        uint256 fyTokenAmount;
        uint256 newUnderlyingTotalSupply;
        uint256 underlyingPrecisionScalar;
    }

    /**
     * @notice An alternative to the usual minting method that does not involve taking on debt.
     *
     * @dev Emits a {SupplyUnderlying} event.
     *
     * Requirements:
     *
     * - Must be called prior to maturation.
     * - The amount to supply cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - The caller must have allowed this contract to spend `underlyingAmount` tokens.
     *
     * @param underlyingAmount The amount of underlying to supply to the Redemption Pool.
     * @return true = success, otherwise it reverts.
     */
    function supplyUnderlying(uint256 underlyingAmount) external override nonReentrant returns (bool) {
        SupplyUnderlyingLocalVars memory vars;

        /* Checks: maturation time. */
        require(block.timestamp < fyToken.expirationTime(), "ERR_BOND_MATURED");

        /* Checks: the zero edge case. */
        require(underlyingAmount > 0, "ERR_SUPPLY_UNDERLYING_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        require(fintroller.getSupplyUnderlyingAllowed(fyToken), "ERR_SUPPLY_UNDERLYING_NOT_ALLOWED");

        /* Effects: update storage. */
        (vars.mathErr, vars.newUnderlyingTotalSupply) = addUInt(totalUnderlyingSupply, underlyingAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_MATH_ERROR");
        totalUnderlyingSupply = vars.newUnderlyingTotalSupply;

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be upscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        if (vars.underlyingPrecisionScalar != 1) {
            (vars.mathErr, vars.fyTokenAmount) = mulUInt(underlyingAmount, vars.underlyingPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_MATH_ERROR");
        } else {
            vars.fyTokenAmount = underlyingAmount;
        }

        /* Interactions: mint the fyTokens. */
        require(fyToken.mint(msg.sender, vars.fyTokenAmount), "ERR_SUPPLY_UNDERLYING_CALL_MINT");

        /* Interactions: perform the Erc20 transfer. */
        fyToken.underlying().safeTransferFrom(msg.sender, address(this), underlyingAmount);

        emit SupplyUnderlying(msg.sender, underlyingAmount, vars.fyTokenAmount);

        return true;
    }

    /**
     * @notice Activate or de-activate the leveraged LP admin lock .
     *
     * Requirements:
     *
     * - Caller must be admin.
     *
     * @param newLock The new value to set the lock to.
     * @return true = admin lock is now activated, otherwise false.
     */
    function setLeveragedLPAdminLock(bool newLock) external override onlyAdmin returns (bool) {
        /* Effects: update storage. */
        isLeveragedLPAdminLocked = newLock;

        return isLeveragedLPAdminLocked;
    }

    struct SupplyUnderlyingForLeveragedLPLocalVars {
        MathError mathErr;
        uint256 fyTokenAmount;
        uint256 newTotalUnderlying;
        uint256 underlyingPrecisionScalar;
        // uint256 slippagePercentage;
        // uint256 underlyingAmountSlippage;
        // uint256 fyTokenAmountSlippage;
        uint256 updatedFyTokenBalance;
        uint256 updatedUnderlyingBalance;
    }

    /**
     * @notice An alternative to the usual minting method that does not involve taking on debt.
     * The sole purpose of this method is to provide liquidity for `underlying:fyToken` pair on Balancer.
     *
     * @dev Emits a {SupplyUnderlyingForLeveragedLP} event.
     *
     * Requirements:
     *
     * - If admin lock is activated, caller must be admin.
     * - Must be called prior to maturation.
     * - The amount to supply cannot be zero.
     * - The Fintroller must allow this action to be performed.
     * - The caller must have allowed this contract to spend `underlyingAmount` tokens.
     *
     * @param underlyingAmount The amount of underlying to supply to the Redemption Pool.
     * @return true = success, otherwise it reverts.
     */
    function supplyUnderlyingForLeveragedLP(uint256 underlyingAmount) external override nonReentrant returns (bool) {
        // TODO: would be better to have the leveraged LP functionality be managed through its own separate contract
        SupplyUnderlyingForLeveragedLPLocalVars memory vars;

        /* Checks: admin lock deactivated or caller is admin. */
        require(!isLeveragedLPAdminLocked || msg.sender == admin, "ERR_NOT_ADMIN");

        /* Checks: maturation time. */
        require(block.timestamp < fyToken.expirationTime(), "ERR_BOND_MATURED");

        /* Checks: the zero edge case. */
        require(underlyingAmount > 0, "ERR_SUPPLY_UNDERLYING_FOR_LEVERAGED_LP_ZERO");

        /* Checks: the Fintroller allows this action to be performed. */
        // TODO: add fintroller rules
        // require(fintroller.getSupplyUnderlyingAllowed(fyToken), ERR_SUPPLY_UNDERLYING_FOR_LEVERAGED_LP_NOT_ALLOWED");

        /* Effects: update storage. */
        (vars.mathErr, vars.newTotalUnderlying) = addUInt(
            leveragedLPPositions[msg.sender].totalUnderlying,
            underlyingAmount
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_FOR_LEVERAGED_LP_MATH_ERROR");
        leveragedLPPositions[msg.sender].totalUnderlying = vars.newTotalUnderlying;

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be upscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        if (vars.underlyingPrecisionScalar != 1) {
            (vars.mathErr, vars.fyTokenAmount) = mulUInt(underlyingAmount, vars.underlyingPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_FOR_LEVERAGED_LP_MATH_ERROR");
        } else {
            vars.fyTokenAmount = underlyingAmount;
        }

        /* Interactions: mint the fyTokens. */
        require(fyToken.mint(address(this), vars.fyTokenAmount), "ERR_SUPPLY_UNDERLYING_FOR_LEVERAGED_LP_CALL_MINT");

        /* Interactions: perform the Erc20 transfer. */
        fyToken.underlying().safeTransferFrom(msg.sender, address(this), underlyingAmount);

        // vars.slippagePercentage = 10;

        /* If the pool hasn't been initialized, initialize it before adding the new liquidity. */
        if (address(bPool) == address(0)) {
            // TODO: BFactory address should be inititalized somewhere
            BPoolInterface bp = BFactoryInterface(address(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd)).newBPool();

            /* Effects: approve infinite allowances for balancer pool (unsafe). */
            fyToken.underlying().approve(address(bp), uint256(-1));
            fyToken.approve(address(bp), uint256(-1));

            /* Effects: set pool percentages (50/50) and supply the initial liquidity by providing token balances. */
            bp.bind(address(fyToken.underlying()), underlyingAmount, 25);
            bp.bind(address(fyToken), vars.fyTokenAmount, 25);

            /* Effects: update storage. */
            bPool = bp;
        } else {
            // TODO: fix slippage handling
            // uint256[] memory maxAmountsIn;
            // (vars.mathErr, vars.underlyingAmountSlippage) = divUInt(underlyingAmount, vars.slippagePercentage);
            // require(vars.mathErr == MathError.NO_ERROR, "ERR_SYNC_BPOOL_MATH_ERROR");
            // maxAmountsIn[0] = underlyingAmount + vars.underlyingAmountSlippage;

            // (vars.mathErr, vars.fyTokenAmountSlippage) = divUInt(vars.fyTokenAmount, vars.slippagePercentage);
            // require(vars.mathErr == MathError.NO_ERROR, "ERR_SYNC_BPOOL_MATH_ERROR");
            // maxAmountsIn[1] = vars.fyTokenAmount + vars.fyTokenAmountSlippage;

            // bPool.joinPool(vars.fyTokenAmount, maxAmountsIn);

            /* Effects: absorb any tokens that may have been sent to the Balancer pool contract. */
            bPool.gulp(address(fyToken.underlying()));
            bPool.gulp(address(fyToken));

            /**
             * calculate the updated fyToken balance (balance after liquidity is provided to Balancer pool).
             */
            (vars.mathErr, vars.updatedUnderlyingBalance) = addUInt(
                underlyingAmount,
                fyToken.underlying().balanceOf(address(bPool))
            );
            require(vars.mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_FOR_LEVERAGED_LP_MATH_ERROR");

            /**
             * calculate the updated underlying balance (balance after liquidity is provided to Balancer pool).
             */
            (vars.mathErr, vars.updatedFyTokenBalance) = addUInt(vars.fyTokenAmount, fyToken.balanceOf(address(bPool)));
            require(vars.mathErr == MathError.NO_ERROR, "ERR_SUPPLY_UNDERLYING_FOR_LEVERAGED_LP_MATH_ERROR");

            /* Effects: set pool percentages (50/50) and supply more liquidity by providing updated balances. */
            bPool.rebind(address(fyToken.underlying()), vars.updatedUnderlyingBalance, 25);
            bPool.rebind(address(fyToken), vars.updatedFyTokenBalance, 25);

            // NOTE: alternative to rebind, we could directly send tokens to pool and then call gulp on each
        }

        emit SupplyUnderlyingForLeveragedLP(msg.sender, underlyingAmount, vars.fyTokenAmount);

        return true;
    }

    struct ExitLeveragedLPLocalVars {
        MathError mathErr;
        uint256 fyTokenAmount;
        uint256 newTotalUnderlying;
        uint256 underlyingPrecisionScalar;
        // uint256 slippagePercentage;
        // uint256 underlyingAmountSlippage;
        // uint256 fyTokenAmountSlippage;
        uint256 updatedFyTokenBalance;
        uint256 updatedUnderlyingBalance;
    }

    /**
     * @notice Exit leveraged LP position.
     *
     * @dev Emits a {ExitLeveragedLP} event.
     *
     * Requirements:
     *
     * - The amount to redeem cannot be zero.
     * - The amount to redeem cannot be larger that the sender's leveraged LP position.
     * - The Fintroller must allow this action to be performed.
     *
     * @param underlyingAmount The amount of underlying to redeem from the Redemption Pool.
     * @return true = success, otherwise it reverts.
     */
    function exitLeveragedLP(uint256 underlyingAmount) external override nonReentrant returns (bool) {
        ExitLeveragedLPLocalVars memory vars;
        // vars.slippagePercentage = 10;

        /* Checks: the zero edge case. */
        require(underlyingAmount > 0, "EXIT_LEVERAGED_LP_ZERO");

        /* Checks: the zero edge case. */
        require(
            underlyingAmount <= leveragedLPPositions[msg.sender].totalUnderlying,
            "EXIT_LEVERAGED_LP_ABOVE_POSITION"
        );

        /* Checks: the Fintroller allows this action to be performed. */
        // TODO: add fintroller rules
        // require(fintroller.getSupplyUnderlyingAllowed(fyToken), ERR_EXIT_LEVERAGED_LP_NOT_ALLOWED");

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be upscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        // vars.fyTokenAmount = lpTokenAmount;
        // // TODO: fix to use lp token scalar precision instead.
        // vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        // if (vars.underlyingPrecisionScalar != 1) {
        //     (vars.mathErr, vars.underlyingAmount) = divUInt(lpTokenAmount, vars.underlyingPrecisionScalar);
        //     require(vars.mathErr == MathError.NO_ERROR, "ERR_EXIT_LEVERAGED_LP_MATH_ERROR");
        // } else {
        //     vars.underlyingAmount = lpTokenAmount;
        // }

        // uint256[] memory minAmountsOut;
        // (vars.mathErr, vars.underlyingAmountSlippage) = divUInt(vars.underlyingAmount, vars.slippagePercentage);
        // require(vars.mathErr == MathError.NO_ERROR, "ERR_EXIT_LEVERAGED_LP_MATH_ERROR");
        // minAmountsOut[0] = vars.underlyingAmount - vars.underlyingAmountSlippage;

        // (vars.mathErr, vars.fyTokenAmountSlippage) = divUInt(vars.fyTokenAmount, vars.slippagePercentage);
        // require(vars.mathErr == MathError.NO_ERROR, "ERR_EXIT_LEVERAGED_LP_MATH_ERROR");
        // minAmountsOut[1] = vars.fyTokenAmount - vars.fyTokenAmountSlippage;

        // bPool.exitPool(lpTokenAmount, minAmountsOut);

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be upscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        if (vars.underlyingPrecisionScalar != 1) {
            (vars.mathErr, vars.fyTokenAmount) = mulUInt(underlyingAmount, vars.underlyingPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_EXIT_LEVERAGED_LP_MATH_ERROR");
        } else {
            vars.fyTokenAmount = underlyingAmount;
        }

        /* Effects: absorb any tokens that may have been sent to the Balancer pool contract. */
        bPool.gulp(address(fyToken.underlying()));
        bPool.gulp(address(fyToken));

        // TODO: handle cases of not enough fyTokens or underlying in the pool
        /**
         * calculate the updated fyToken balance (balance after liquidity is withdrawn from Balancer pool).
         */
        (vars.mathErr, vars.updatedUnderlyingBalance) = subUInt(
            fyToken.underlying().balanceOf(address(bPool)),
            underlyingAmount
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_EXIT_LEVERAGED_LP_MATH_ERROR");

        /**
         * calculate the updated underlying balance (balance after liquidity is withdrawn from Balancer pool).
         */
        (vars.mathErr, vars.updatedFyTokenBalance) = subUInt(fyToken.balanceOf(address(bPool)), vars.fyTokenAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_EXIT_LEVERAGED_LP_MATH_ERROR");

        /* Effects: set pool percentages (50/50) and partially withdraw liquidity by providing updated balances. */
        bPool.rebind(address(fyToken.underlying()), vars.updatedUnderlyingBalance, 25);
        bPool.rebind(address(fyToken), vars.updatedFyTokenBalance, 25);

        /* Interactions: burn the fyTokens. */
        require(fyToken.burn(msg.sender, vars.fyTokenAmount), "ERR_EXIT_LEVERAGED_LP_CALL_BURN");

        /* Interactions: perform the Erc20 transfer. */
        fyToken.underlying().safeTransferFrom(address(this), msg.sender, underlyingAmount);

        /* Effects: update storage. */
        (vars.mathErr, vars.newTotalUnderlying) = subUInt(
            leveragedLPPositions[msg.sender].totalUnderlying,
            underlyingAmount
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_EXIT_LEVERAGED_LP_MATH_ERROR");
        leveragedLPPositions[msg.sender].totalUnderlying = vars.newTotalUnderlying;

        emit ExitLeveragedLP(msg.sender, underlyingAmount, vars.fyTokenAmount);

        return true;
    }
}
