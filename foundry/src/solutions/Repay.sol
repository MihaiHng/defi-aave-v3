// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPool} from "../interfaces/aave-v3/IPool.sol";
import {IVariableDebtToken} from "../interfaces/aave-v3/IVariableDebtToken.sol";
import {POOL} from "../Constants.sol";

contract Repay {
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

    function borrow(address token, uint256 amount) public {
        pool.borrow({
            asset: token,
            amount: amount,
            // 1 = Stable interest rate
            // 2 = Variable interest rate
            interestRateMode: 2,
            referralCode: 0,
            onBehalfOf: address(this)
        });
    }

    function getVariableDebt(address token) public view returns (uint256) {
        IPool.ReserveData memory reserve = pool.getReserveData(token);
        return
            IERC20(reserve.variableDebtTokenAddress).balanceOf(address(this));
    }

    function repay(address token) public returns (uint256) {
        // msg.sender pays for interest on borrow.
        // Transfer the difference (debt - balance in this contract)
        uint256 bal = IERC20(token).balanceOf(address(this));
        uint256 debt = getVariableDebt(token);
        if (debt > bal) {
            IERC20(token).transferFrom(msg.sender, address(this), debt - bal);
        }
        IERC20(token).approve(address(pool), debt);

        uint256 repaid = pool.repay({
            asset: token,
            // max = repay all debt
            amount: type(uint256).max,
            interestRateMode: 2,
            onBehalfOf: address(this)
        });

        return repaid;
    }
}
