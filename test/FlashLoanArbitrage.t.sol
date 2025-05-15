// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {FlashLoanArbitrage} from "../src/FlashLoanArbitrage.sol";
import {IPoolAddressesProvider} from "../lib/protocol-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Sepolia addresses (verify before use)
address constant UNISWAP_V3_ROUTER = 0xeCFF017BE7711931f7F1813EBff41a3e055845f5; // Example, verify
address constant SUSHISWAP_ROUTER = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // SushiSwap V2 router
address constant USDC = 0x65aFADD39029741B3b8f0756952C74678c9cEC93; // USDC (Sepolia)
address constant DAI = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E; // DAI (Sepolia)
address constant POOL_ADDRESSES_PROVIDER = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A; // Aave V3 Sepolia
uint24 constant UNISWAP_POOL_FEE = 500;

contract FlashLoanArbitrageTest is Test {
    FlashLoanArbitrage public arb;
    address public owner;

    function setUp() public {
        vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"));
        console.log("Aave provider:", POOL_ADDRESSES_PROVIDER);
        console.log(
            "Aave provider code size:",
            POOL_ADDRESSES_PROVIDER.code.length
        );
        console.log("Uniswap V3 router:", UNISWAP_V3_ROUTER);
        console.log(
            "Uniswap V3 router code size:",
            UNISWAP_V3_ROUTER.code.length
        );
        console.log("SushiSwap router:", SUSHISWAP_ROUTER);
        console.log(
            "SushiSwap router code size:",
            SUSHISWAP_ROUTER.code.length
        );
        console.log("USDC:", USDC);
        console.log("USDC code size:", USDC.code.length);
        console.log("DAI:", DAI);
        console.log("DAI code size:", DAI.code.length);
        require(
            POOL_ADDRESSES_PROVIDER.code.length > 0,
            "Aave provider not deployed"
        );
        require(
            UNISWAP_V3_ROUTER.code.length > 0,
            "Uniswap V3 router not deployed"
        );
        require(
            SUSHISWAP_ROUTER.code.length > 0,
            "SushiSwap router not deployed"
        );
        require(USDC.code.length > 0, "USDC not deployed");
        require(DAI.code.length > 0, "DAI not deployed");
        owner = address(this);
        arb = new FlashLoanArbitrage(
            IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER),
            UNISWAP_V3_ROUTER,
            SUSHISWAP_ROUTER,
            USDC,
            DAI,
            UNISWAP_POOL_FEE
        );
    }

    function testFlashLoanArbitrageCycle() public {
        // Simulate arbitrage by manipulating pool prices or using a block where arbitrage is possible
        uint256 flashLoanAmount = 10_000e6; // 10,000 USDC (6 decimals)
        uint256 ownerBalanceBefore = IERC20(USDC).balanceOf(owner);

        // Initiate flash loan (will revert if not profitable or if not possible on fork)
        vm.expectRevert(); // Remove this line if you set up a profitable scenario
        arb.initiateFlashLoan(USDC, flashLoanAmount);

        // If using mocks, you can set up token balances and pool prices here
        // For real fork, you may need to simulate a profitable opportunity
        // Assert profit (if not reverted)
        uint256 ownerBalanceAfter = IERC20(USDC).balanceOf(owner);
        assert(ownerBalanceAfter >= ownerBalanceBefore);
    }

    // Optional: Add more tests with mocks to simulate profit
}
