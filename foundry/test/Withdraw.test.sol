// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {POOL, WETH} from "../src/Constants.sol";
import {IPool} from "../src/interfaces/aave-v3/IPool.sol";
import {Withdraw} from "@exercises/Withdraw.sol";

contract WithdrawTest is Test {
    IERC20 private constant weth = IERC20(WETH);
    IPool private constant pool = IPool(POOL);
    IERC20 private aWeth;
    Withdraw private target;

    function setUp() public {
        // Get aWETH address
        IPool.ReserveData memory reserve = pool.getReserveData(WETH);
        aWeth = IERC20(reserve.aTokenAddress);

        deal(WETH, address(this), 1e18);
        target = new Withdraw();

        weth.approve(address(target), 1e18);
        target.supply(WETH, 1e18);

        // Let supply interest increase
        skip(7 * 24 * 3600);
    }

    function test_withdraw() public {
        uint256 aWethBalBefore = aWeth.balanceOf(address(target));
        uint256 amount = aWethBalBefore;
        uint256 withdrawn = target.withdraw(WETH, amount);
        uint256 aWethBalAfter = aWeth.balanceOf(address(target));

        console.log("WETH balance: %e", aWethBalBefore);

        assertGt(aWethBalBefore, 0, "aWETH balance = 0");
        assertEq(aWethBalAfter, 0, "aWETH balance after");
        assertEq(withdrawn, aWethBalBefore, "aWETH balance");
        assertEq(
            weth.balanceOf(address(target)),
            withdrawn,
            "WETH balance of target"
        );
    }
}
