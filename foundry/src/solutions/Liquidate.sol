// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {console} from "forge-std/Test.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPool} from "../interfaces/aave-v3/IPool.sol";
import {POOL} from "../Constants.sol";

contract Liquidate {
    IPool public constant pool = IPool(POOL);

    function liquidate(
        address collateral,
        address borrowedToken,
        address user
    ) public {
        IPool.ReserveData memory reserve = pool.getReserveData(borrowedToken);
        uint256 debt = IERC20(reserve.variableDebtTokenAddress).balanceOf(user);

        IERC20(borrowedToken).transferFrom(msg.sender, address(this), debt);
        IERC20(borrowedToken).approve(address(pool), debt);

        pool.liquidationCall({
            collateralAsset: collateral,
            debtAsset: borrowedToken,
            user: user,
            debtToCover: debt,
            receiveAToken: false
        });
    }
}
