# Aave V3 Flash Loan Arbitrage (Foundry)

## Overview
This project demonstrates a complete arbitrage cycle using Aave V3 flash loans, Uniswap V3, and SushiSwap. It is built with [Foundry](https://book.getfoundry.sh/) and includes:
- A smart contract to borrow funds via a flash loan, perform arbitrage between Uniswap and SushiSwap, and repay the loan in a single transaction.
- Deployment scripts for Goerli/Sepolia.
- Comprehensive tests using mainnet/testnet forking.

## Arbitrage Flow
1. **Borrow**: The contract borrows funds (e.g., USDC) from Aave V3 using a flash loan.
2. **Swap 1**: It swaps the borrowed USDC for DAI on Uniswap V3.
3. **Swap 2**: It swaps the DAI back to USDC on SushiSwap (Uniswap V2 interface), aiming for a profit.
4. **Repay**: The contract repays the flash loan plus premium to Aave.
5. **Profit**: Any remaining USDC is profit, which can be withdrawn by the contract owner.

## Project Structure
- `src/FlashLoanArbitrage.sol`: Main arbitrage contract.
- `test/FlashLoanArbitrage.t.sol`: Foundry test simulating the arbitrage cycle.
- `script/DeployFlashLoanArbitrage.s.sol`: Deployment script for Goerli/Sepolia.
- `lib/`: External dependencies (Aave, Uniswap, OpenZeppelin, etc.).

## Key Features
- Inherits from Aave's `FlashLoanSimpleReceiverBase`.
- Uses Uniswap V3 and SushiSwap routers for swaps.
- Emits events for loan, swaps, repayment, and profit.
- Gas optimized and includes error handling.
- Fully commented for educational clarity.

## Deployment
1. **Set up environment variables:**
   - `PRIVATE_KEY`: Your deployer private key (with testnet ETH).
   - `RPC_URL`: Goerli/Sepolia RPC endpoint.
2. **Deploy:**
   ```sh
   forge script script/DeployFlashLoanArbitrage.s.sol --rpc-url $RPC_URL --broadcast
   ```

## Testing
1. **Set up environment variable:**
   - `MAINNET_RPC_URL`: Mainnet RPC endpoint for forking.
2. **Run tests:**
   ```sh
   forge test
   ```
   The test forks mainnet, deploys the contract, and simulates the arbitrage cycle. You can extend the test to use mocks for full control over pool prices and profit scenarios.

## Customization
- Update token/router addresses in the deployment script and test as needed for your network.
- Adjust slippage and minimum output parameters for production use.

## Security & Warnings
- This code is for educational/demo purposes. Do not use in production without thorough audits.
- Flash loan arbitrage is highly competitive and risky on mainnet.

## License
MIT
