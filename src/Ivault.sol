// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface Ivault is IERC20 {
    function optimisticMint(uint256 underlyingAmount) external returns (uint256);

    function getAmountShares(uint256 underlyingAmount) external pure returns (uint256);
}
