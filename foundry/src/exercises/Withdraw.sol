// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPool} from "../interfaces/aave-v3/IPool.sol";
import {POOL} from "../Constants.sol";

contract Withdraw {
    IPool public constant pool = IPool(POOL);

    function supply(address token, uint256 amount) public {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(address(pool), amount);
        pool.supply({
            asset: token,
            amount: amount,
            onBehalfOf: address(this),
            referralCode: 0
        });
    }

    // Task 1 - Get aToken balance of this contract
    // The aToken balance is the amount of underlying token that this contract
    // can withdraw
    function getSupplyBalance(address token) public view returns (uint256) {
        // Task 1.1 - Get the aToken address from the pool contract
        IPool.ReserveData memory reserve = pool.getReserveData(token);
        // Task 1.2 - Get the balance of aToken that this contract has
        return IERC20(reserve.aTokenAddress).balanceOf(address(this));
    }

    // Task 2 - Withdraw all of underlying token from Aave V3
    function withdraw(address token, uint256 amount) public returns (uint256) {
        // Task 2.1 - Withdraw all of underlying token from Aave V3
        uint256 withrawnAmount = pool.withdraw({
            asset: token,
            amount: amount,
            to: address(this)
        });
        // Task 2.2 - Return the amount that was withdrawn
        return withrawnAmount;
    }
}
