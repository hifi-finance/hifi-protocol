/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "@paulrberg/contracts/access/Admin.sol";
import "@paulrberg/contracts/math/CarefulMath.sol";
import "@paulrberg/contracts/token/erc20/Erc20Interface.sol";
import "@paulrberg/contracts/token/erc20/Erc20Recover.sol";
import "@paulrberg/contracts/token/erc20/SafeErc20.sol";
import "@paulrberg/contracts/utils/ReentrancyGuard.sol";

import "./BAMMControllerInterface.sol";
import "./external/balancer/BFactoryInterface.sol";

/**
 * @title BAMMController
 * @author Hifi
 * @notice Provides capital efficient AMM so that there is sufficient liquidity
 * for reasonable size lending and borrowing positions to take place.
 * @dev Instantiated by the fyToken in its constructor.
 */
contract BAMMController is
    CarefulMath, /* no dependency */
    ReentrancyGuard, /* no dependency */
    BAMMControllerInterface, /* one dependency */
    Admin, /* two dependencies */
    Erc20Recover /* five dependencies */
{
    using SafeErc20 for Erc20Interface;

    /**
     * @param fyToken_ The address of the fyToken contract.
     */
    constructor(FyTokenInterface fyToken_) Admin() {
        /**
         * Set the fyToken contract. It cannot be sanity-checked because the fyToken creates this
         * contract in its own constructor and contracts cannot be called while initializing.
         */
        fyToken = fyToken_;
    }

    /**
     * @notice Activate or de-activate the admin lock .
     *
     * Requirements:
     *
     * - Caller must be admin.
     *
     * @param newLock The new value to set the lock to.
     * @return true = admin lock is now activated, otherwise false.
     */
    function setAdminLock(bool newLock) external override onlyAdmin returns (bool) {
        /* Effects: update storage. */
        isAdminLocked = newLock;

        return isAdminLocked;
    }

    struct InjectLiquidityLocalVars {
        MathError mathErr;
        uint256 fyTokenAmount;
        uint256 newTotalUnderlying;
        uint256 underlyingPrecisionScalar;
        uint256 updatedUnderlyingBalance;
        uint256 updatedFyTokenBalance;
    }

    /**
     * @notice Provides liquidity for the `underlying:fyToken` pair on Balancer by taking an underlying amount
     * from the user, minting the equivalent amount of fyTokens, and injecting that liquidity into the pair's
     * Balancer pool.
     *
     * @dev Emits an {InjectLiquidity} event.
     *
     * Requirements:
     *
     * - If admin lock is activated, caller must be admin.
     * - Must be called prior to maturation.
     * - The amount to supply cannot be zero.
     * - The caller must have allowed this contract to spend `underlyingAmount` tokens.
     *
     * @param underlyingAmount The amount of underlying tokens to use for injecting liquidity.
     * @return true = success, otherwise it reverts.
     */
    function injectLiquidity(uint256 underlyingAmount) external override nonReentrant returns (bool) {
        InjectLiquidityLocalVars memory vars;

        /* Checks: admin lock deactivated or caller is admin. */
        require(!isAdminLocked || msg.sender == admin, "ERR_NOT_ADMIN");

        /* Checks: maturation time. */
        require(block.timestamp < fyToken.expirationTime(), "ERR_BOND_MATURED");

        /* Checks: the zero edge case. */
        require(underlyingAmount > 0, "ERR_INJECT_LIQUIDITY_ZERO");

        /* Effects: update storage. */
        (vars.mathErr, vars.newTotalUnderlying) = addUInt(positions[msg.sender].totalUnderlying, underlyingAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_INJECT_LIQUIDITY_MATH_ERROR");
        positions[msg.sender].totalUnderlying = vars.newTotalUnderlying;

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be upscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        if (vars.underlyingPrecisionScalar != 1) {
            (vars.mathErr, vars.fyTokenAmount) = mulUInt(underlyingAmount, vars.underlyingPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_INJECT_LIQUIDITY_MATH_ERROR");
        } else {
            vars.fyTokenAmount = underlyingAmount;
        }

        /* Interactions: mint the fyTokens. */
        require(fyToken.mint(address(this), vars.fyTokenAmount), "ERR_INJECT_LIQUIDITY_CALL_MINT");

        /* Interactions: perform the Erc20 transfer. */
        fyToken.underlying().safeTransferFrom(msg.sender, address(this), underlyingAmount);

        /* If the pool hasn't been created, create and initialize it before adding the new liquidity. */
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
            /* Effects: absorb any tokens that may have been sent to the Balancer pool contract. */
            // TODO: determine if that is really necessary or if it opens up an attack vector
            bPool.gulp(address(fyToken.underlying()));
            bPool.gulp(address(fyToken));

            /**
             * calculate the updated fyToken balance (balance after liquidity is provided to Balancer pool).
             */
            (vars.mathErr, vars.updatedUnderlyingBalance) = addUInt(
                underlyingAmount,
                bPool.getBalance(address(fyToken.underlying()))
            );
            require(vars.mathErr == MathError.NO_ERROR, "ERR_INJECT_LIQUIDITY_MATH_ERROR");

            /**
             * calculate the updated underlying balance (balance after liquidity is provided to Balancer pool).
             */
            (vars.mathErr, vars.updatedFyTokenBalance) = addUInt(
                vars.fyTokenAmount,
                bPool.getBalance(address(fyToken))
            );
            require(vars.mathErr == MathError.NO_ERROR, "ERR_INJECT_LIQUIDITY_MATH_ERROR");

            /* Effects: set pool percentages (50/50) and supply more liquidity by providing updated balances. */
            bPool.rebind(address(fyToken.underlying()), vars.updatedUnderlyingBalance, 25);
            bPool.rebind(address(fyToken), vars.updatedFyTokenBalance, 25);

            // NOTE: alternative to rebind, we could directly send tokens to pool and then call gulp on each
        }

        emit InjectLiquidity(msg.sender, underlyingAmount, vars.fyTokenAmount);

        return true;
    }

    struct ExtractLiquidityLocalVars {
        MathError mathErr;
        uint256 fyTokenAmount;
        uint256 newTotalUnderlying;
        uint256 underlyingPrecisionScalar;
        uint256 updatedUnderlyingBalance;
        uint256 updatedFyTokenBalance;
    }

    /**
     * @notice Extracts liquidity previously provisioned to the Balancer pool.
     *
     * @dev Emits a {ExtractLiquidity} event.
     *
     * Requirements:
     *
     * - The amount to extract cannot be zero.
     * - The amount to extract cannot be larger that the sender's open position.
     *
     * @param underlyingAmount The amount of underlying tokens to extract from the Balancer pool
     * liquidity (matched with the equivalent amount of fyTokens).
     * @return true = success, otherwise it reverts.
     */
    function extractLiquidity(uint256 underlyingAmount) external override nonReentrant returns (bool) {
        ExtractLiquidityLocalVars memory vars;

        /* Checks: the zero edge case. */
        require(underlyingAmount > 0, "EXTRACT_LIQUIDITY_ZERO");

        /* Checks: the insufficient position case. */
        require(underlyingAmount <= positions[msg.sender].totalUnderlying, "EXTRACT_LIQUIDITY_INSUFFICIENT_POSITION");

        /**
         * fyTokens always have 18 decimals so the underlying amount needs to be upscaled.
         * If the precision scalar is 1, it means that the underlying also has 18 decimals.
         */
        vars.underlyingPrecisionScalar = fyToken.underlyingPrecisionScalar();
        if (vars.underlyingPrecisionScalar != 1) {
            (vars.mathErr, vars.fyTokenAmount) = mulUInt(underlyingAmount, vars.underlyingPrecisionScalar);
            require(vars.mathErr == MathError.NO_ERROR, "ERR_EXTRACT_LIQUIDITY_MATH_ERROR");
        } else {
            vars.fyTokenAmount = underlyingAmount;
        }

        /* Effects: absorb any tokens that may have been sent to the Balancer pool contract. */
        // TODO: determine if that is really necessary or if it opens up an attack vector
        bPool.gulp(address(fyToken.underlying()));
        bPool.gulp(address(fyToken));

        // TODO: handle cases of not enough fyTokens or underlying in the pool
        /**
         * calculate the updated fyToken balance (balance after liquidity is withdrawn from Balancer pool).
         */
        (vars.mathErr, vars.updatedUnderlyingBalance) = subUInt(
            bPool.getBalance(address(fyToken.underlying())),
            underlyingAmount
        );
        require(vars.mathErr == MathError.NO_ERROR, "ERR_EXTRACT_LIQUIDITY_MATH_ERROR");

        /**
         * calculate the updated underlying balance (balance after liquidity is withdrawn from Balancer pool).
         */
        (vars.mathErr, vars.updatedFyTokenBalance) = subUInt(bPool.getBalance(address(fyToken)), vars.fyTokenAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_EXTRACT_LIQUIDITY_MATH_ERROR");

        /* Effects: set pool percentages (50/50) and partially withdraw liquidity by providing updated balances. */
        bPool.rebind(address(fyToken.underlying()), vars.updatedUnderlyingBalance, 25);
        bPool.rebind(address(fyToken), vars.updatedFyTokenBalance, 25);

        /* Interactions: burn the fyTokens. */
        require(fyToken.burn(msg.sender, vars.fyTokenAmount), "ERR_EXTRACT_LIQUIDITY_CALL_BURN");

        /* Interactions: perform the Erc20 transfer. */
        fyToken.underlying().safeTransfer(msg.sender, underlyingAmount);

        /* Effects: update storage. */
        (vars.mathErr, vars.newTotalUnderlying) = subUInt(positions[msg.sender].totalUnderlying, underlyingAmount);
        require(vars.mathErr == MathError.NO_ERROR, "ERR_EXTRACT_LIQUIDITY_MATH_ERROR");
        positions[msg.sender].totalUnderlying = vars.newTotalUnderlying;

        emit ExtractLiquidity(msg.sender, underlyingAmount, vars.fyTokenAmount);

        return true;
    }
}
