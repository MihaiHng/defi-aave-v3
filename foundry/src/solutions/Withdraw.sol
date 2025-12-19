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

    function getSupplyBalance(address token) public view returns (uint256) {
        IPool.ReserveData memory reserve = pool.getReserveData(token);
        return IERC20(reserve.aTokenAddress).balanceOf(address(this));
    }

    function withdraw(address token, uint256 amount) public returns (uint256) {
        uint256 withdrawn = pool.withdraw({
            asset: token,
            amount: amount,
            to: address(this)
        });
        return withdrawn;
    }
}
