// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeVault is ERC20 {
    address adminHook;
    address token;

    constructor(address _adminHook, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        adminHook = _adminHook;
    }

    function optimisticMint(uint256 underlyingAmount) public returns (uint256) {
        require(msg.sender == adminHook, "Only the allowed hook can call this function");
        uint256 sharesAmount = getAmountShares(underlyingAmount);
        _mint(msg.sender, sharesAmount);
        return sharesAmount;
    }

    function getAmountShares(uint256 underlyingAmount) public pure returns (uint256) {
        return underlyingAmount;
    }
}
