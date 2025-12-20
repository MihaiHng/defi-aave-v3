// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {POOL, ORACLE, WETH, DAI} from "../src/Constants.sol";
import {IPool} from "../src/interfaces/aave-v3/IPool.sol";
import {IAaveOracle} from "../src/interfaces/aave-v3/IAaveOracle.sol";
import {Liquidate} from "@exercises/Liquidate.sol";

contract LiquidateTest is Test {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IPool private constant pool = IPool(POOL);
    IAaveOracle private constant oracle = IAaveOracle(ORACLE);
    Liquidate private target;

    function setUp() public {
        // Supply
        deal(WETH, address(this), 1e18);
        weth.approve(address(pool), type(uint256).max);
        pool.supply({
            asset: WETH,
            amount: 1e18,
            onBehalfOf: address(this),
            referralCode: 0
        });

        // Borrow
        vm.mockCall(
            ORACLE,
            abi.encodeCall(IAaveOracle.getAssetPrice, (WETH)),
            abi.encode(uint256(2000 * 1e8))
        );
        pool.borrow({
            asset: DAI,
            amount: 1000 * 1e18,
            interestRateMode: 2,
            referralCode: 0,
            onBehalfOf: address(this)
        });

        uint256 ethPrice = 500 * 1e8;

        vm.mockCall(
            ORACLE,
            abi.encodeCall(IAaveOracle.getAssetPrice, (WETH)),
            abi.encode(ethPrice)
        );

        target = new Liquidate();

        // Approve target to spend DAI
        deal(DAI, address(this), 10000 * 1e18);
        dai.approve(address(target), 10000 * 1e18);
    }

    function test_liquidate() public {
        (uint256 colUsdBefore, uint256 debtUsdBefore, , , , ) = pool
            .getUserAccountData(address(this));

        target.liquidate(WETH, DAI, address(this));

        (uint256 colUsdAfter, uint256 debtUsdAfter, , , , ) = pool
            .getUserAccountData(address(this));

        assertLt(colUsdAfter, colUsdBefore, "USD collateral after");
        assertLt(debtUsdAfter, debtUsdBefore, "USD debt after");

        uint256 wethBal = weth.balanceOf(address(target));
        console.log("WETH balance: %e", wethBal);
        assertGt(wethBal, 0, "WETH balance");
    }
}
