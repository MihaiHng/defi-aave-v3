// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";
import {IERC20, IERC20Metadata} from "../interfaces/IERC20.sol";
import {IPool} from "../interfaces/aave-v3/IPool.sol";
import {IAaveOracle} from "../interfaces/aave-v3/IAaveOracle.sol";
import {POOL, ORACLE} from "../Constants.sol";

contract Borrow {
    IPool public constant pool = IPool(POOL);
    IAaveOracle public constant oracle = IAaveOracle(ORACLE);

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

    // Task 1 - Approximate the maximum amount of token that can be borrowed
    function approxMaxBorrow(address token) public view returns (uint256) {
        uint256 tokenPrice = oracle.getAssetPrice(token);
        uint8 tokenDecimals = IERC20Metadata(token).decimals();
        (, , uint256 availableToBorrowUsd, , , ) = pool.getUserAccountData(
            address(this)
        );

        return (availableToBorrowUsd * (10 ** tokenDecimals)) / tokenPrice;
    }

    // Task 2 - Get the health factor of this contract
    function getHealthFactor() public view returns (uint256) {
        (, , , , , uint256 healthFactor) = pool.getUserAccountData(
            address(this)
        );

        return healthFactor;
    }

    // Task 3 - Borrow token from Aave V3
    function borrow(address token, uint256 amount) public {
        pool.borrow({
            asset: token,
            amount: amount,
            interestRateMode: 2,
            referralCode: 0,
            onBehalfOf: address(this)
        });
    }

    // Task 4 - Get variable debt balance of this contract
    function getVariableDebt(address token) public view returns (uint256) {
        IPool.ReserveData memory reserve = pool.getReserveData(token);
        address variableDebtAddress = reserve.variableDebtTokenAddress;

        return IERC20(variableDebtAddress).balanceOf(address(this));
    }
}
