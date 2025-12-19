// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {POOL, ORACLE, WETH, DAI} from "../src/Constants.sol";
import {IPool} from "../src/interfaces/aave-v3/IPool.sol";
import {IAaveOracle} from "../src/interfaces/aave-v3/IAaveOracle.sol";
import {Repay} from "@exercises/Repay.sol";

contract RepayTest is Test {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IPool private constant pool = IPool(POOL);
    IAaveOracle private constant oracle = IAaveOracle(ORACLE);
    IERC20 private debtToken;
    Repay private target;

    function setUp() public {
        deal(WETH, address(this), 1e18);
        target = new Repay();

        weth.approve(address(target), 1e18);
        target.supply(WETH, 1e18);

        IPool.ReserveData memory reserve = pool.getReserveData(DAI);
        debtToken = IERC20(reserve.variableDebtTokenAddress);

        (, , uint256 availableToBorrowUsd, , , ) = pool.getUserAccountData(
            address(target)
        );

        // Approximate max borrow = available USD * DAI decimals / 1e8
        // 1 USD = 1e8
        uint256 approxMaxBorrow = availableToBorrowUsd * (10 ** 10);
        // 50% of approx max borrow
        uint256 borrowAmount = (approxMaxBorrow * 50) / 100;
        console.log("Approximate max borrow: %e", approxMaxBorrow);
        console.log("Borrow amount: %e", borrowAmount);
        target.borrow(DAI, borrowAmount);

        // Mint DAI and allow target to spend
        deal(DAI, address(this), 1000 * 1e18);
        dai.approve(address(target), type(uint256).max);
    }

    function test_repay() public {
        // Test increase in debt over time
        uint256 debt0 = debtToken.balanceOf(address(target));
        console.log("Debt: %e", debt0);
        assertEq(debt0, target.getVariableDebt(DAI), "debt 0");

        skip(7 * 24 * 3600);

        uint256 debt1 = debtToken.balanceOf(address(target));
        console.log("Debt: %e", debt1);
        assertEq(debt1, target.getVariableDebt(DAI), "debt 1");

        // Test repay
        assertGt(debtToken.balanceOf(address(target)), 0, "debt before repay");
        assertGt(dai.balanceOf(address(target)), 0, "DAI before repay");

        uint256 repaid = target.repay(DAI);

        assertEq(debtToken.balanceOf(address(target)), 0, "debt after repay");
        assertEq(dai.balanceOf(address(target)), 0, "DAI after repay");
        assertGt(repaid, 0, "repaid");
    }
}
