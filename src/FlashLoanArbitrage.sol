// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FlashLoanSimpleReceiverBase} from "../lib/protocol-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "../lib/protocol-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {ISwapRouter} from "../lib/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV2Router02} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract FlashLoanArbitrage is FlashLoanSimpleReceiverBase {
    address public owner;
    ISwapRouter public immutable uniswapV3Router;
    IUniswapV2Router02 public immutable sushiSwapRouter;
    address public immutable tokenA; // USDC
    address public immutable tokenB; // DAI
    uint24 public immutable uniswapPoolFee;

    event FlashLoanInitiated(address asset, uint256 amount);
    event SwapOnUniswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    event SwapOnSushi(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    event FlashLoanRepaid(address asset, uint256 totalOwed);
    event Profit(uint256 profitAmount);

    error NotOwner();
    error InsufficientProfit();
    error FlashLoanNotRepaid();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(
        IPoolAddressesProvider provider,
        address _uniswapV3Router,
        address _sushiSwapRouter,
        address _tokenA,
        address _tokenB,
        uint24 _uniswapPoolFee
    ) FlashLoanSimpleReceiverBase(provider) {
        owner = msg.sender;
        uniswapV3Router = ISwapRouter(_uniswapV3Router);
        sushiSwapRouter = IUniswapV2Router02(_sushiSwapRouter);
        tokenA = _tokenA;
        tokenB = _tokenB;
        uniswapPoolFee = _uniswapPoolFee;
    }

    // Initiate a flash loan for arbitrage
    function initiateFlashLoan(
        address asset,
        uint256 amount
    ) external onlyOwner {
        emit FlashLoanInitiated(asset, amount);
        POOL.flashLoanSimple(address(this), asset, amount, bytes(""), 0);
    }

    // This function is called by Aave after the contract receives the flash loaned amount
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "Caller must be POOL");
        require(initiator == address(this), "Initiator must be this contract");

        // Step 1: Swap borrowed TokenB (DAI) for TokenA (USDC) on Uniswap V3
        IERC20(tokenB).approve(address(uniswapV3Router), amount);
        ISwapRouter.ExactInputSingleParams memory uniParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenB,
                tokenOut: tokenA,
                fee: uniswapPoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0, // For test/demo, set to 0. In prod, use oracle/minimum slippage.
                sqrtPriceLimitX96: 0
            });
        uint256 amountOutUni = uniswapV3Router.exactInputSingle(uniParams);
        emit SwapOnUniswap(tokenB, tokenA, amount, amountOutUni);

        // Step 2: Swap TokenA (USDC) for TokenB (DAI) on SushiSwap (Uniswap V2 interface)
        IERC20(tokenA).approve(address(sushiSwapRouter), amountOutUni);
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint256[] memory amounts = sushiSwapRouter.swapExactTokensForTokens(
            amountOutUni,
            0, // For test/demo, set to 0. In prod, use oracle/minimum slippage.
            path,
            address(this),
            block.timestamp
        );
        uint256 amountOutSushi = amounts[amounts.length - 1];
        emit SwapOnSushi(tokenA, tokenB, amountOutUni, amountOutSushi);

        // Step 3: Repay Aave with amount + premium
        uint256 totalOwed = amount + premium;
        IERC20(asset).approve(address(POOL), totalOwed);
        emit FlashLoanRepaid(asset, totalOwed);

        // Step 4: Profit check and event
        uint256 profit = IERC20(asset).balanceOf(address(this)) - totalOwed;
        if (profit > 0) {
            emit Profit(profit);
        } else {
            revert InsufficientProfit();
        }
        return true;
    }

    // Allow owner to withdraw profits
    function withdraw(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0, "Nothing to withdraw");
        IERC20(token).transfer(owner, bal);
    }
}
