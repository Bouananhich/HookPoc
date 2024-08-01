// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Ivault} from "../src/Ivault.sol";
import {FakeVault} from "../src/vault.sol";

contract VaultTest is Test {
    FakeVault vault;

    function setUp() public {
        vault = new FakeVault(address(this), "MyVault", "MVT");
    }

    function testOptimisticMint() public {
        uint256 amount = 1e18;
        assertEq(vault.getAmountShares(amount), amount);
        assertEq(vault.optimisticMint(amount), amount);
        assertEq(vault.balanceOf(address(this)), amount);
    }
}
