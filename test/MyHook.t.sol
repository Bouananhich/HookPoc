// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";
import {MyHook} from "../src/MyHook.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {FakeVault} from "../src/vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract CounterTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    MyHook hook;
    PoolId poolId;
    FakeVault vault;
    Currency currencyX;
    address user = address(12345);

    function setUp() public {
        // creates the pool manager, utility routers, and a test token
        Deployers.deployFreshManagerAndRouters();
        currencyX = Deployers.deployMintAndApproveCurrency();

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
                    | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
            ) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );
        deployCodeTo("MyHook.sol", abi.encode(manager), flags);
        hook = MyHook(flags);

        // Create the vault
        vault = new FakeVault(address(hook), "MyVault", "MVT");
        Currency vaultCurrency = Currency.wrap(address(vault));

        // Vault ERC20 approvals
        address[8] memory toApprove = [
            address(swapRouter),
            address(swapRouterNoChecks),
            address(modifyLiquidityRouter),
            address(modifyLiquidityNoChecks),
            address(donateRouter),
            address(takeRouter),
            address(claimsRouter),
            address(nestedActionRouter.executor())
        ];

        for (uint256 i = 0; i < toApprove.length; i++) {
            IERC20(address(vault)).approve(toApprove[i], type(uint256).max);
        }

        // Create the pool
        //key = PoolKey(currencyX, vaultCurrency, 3000, 60, IHooks(hook));
        deal(address(vault), address(this), 2 ** 255);
        key = PoolKey(vaultCurrency, currencyX, 3000, 60, IHooks(hook));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);

        // Provide full-range liquidity to the pool
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10_000 ether, 0),
            ZERO_BYTES
        );
    }

    function testCounterHooks() public {
        // Check values before swap
        assertEq(hook.beforeSwapCount(poolId), 0);
        assertEq(hook.afterSwapCount(poolId), 0);
        console.log("hello there");

        // Deal tokens to simulated user
        IERC20(Currency.unwrap(currencyX)).transfer(user, 1e18);
        console.log("hello");

        // Setup swap parameters
        bool zeroForOne = true;
        int256 amountSpecified = -1e18; // negative number indicates exact input swap!

        vm.prank(user);
        IERC20(Currency.unwrap(currencyX)).approve(address(manager), 2e18);
        vm.prank(user);
        IERC20(address(vault)).approve(address(manager), 1e18);

        // Perform swap
        vm.prank(user);
        BalanceDelta swapDelta = swap(key, zeroForOne, amountSpecified, ZERO_BYTES);

        // Check values after swap
        assertEq(hook.beforeSwapCount(poolId), 1);
        assertEq(hook.afterSwapCount(poolId), 1);
    }
}
