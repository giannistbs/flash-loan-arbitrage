// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {FlashLoanArbitrage} from "../src/FlashLoanArbitrage.sol";
import {IPoolAddressesProvider} from "../lib/protocol-v3/contracts/interfaces/IPoolAddressesProvider.sol";

contract DeployFlashLoanArbitrage is Script {
    // Example addresses for Goerli/Sepolia (replace with actual addresses as needed)
    address constant UNISWAP_V3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; // Uniswap V3 router
    address constant SUSHISWAP_ROUTER =
        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // SushiSwap router (checksummed)
    address constant USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // USDC (Goerli, checksummed)
    address constant DAI = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844; // DAI (Goerli, checksummed)
    address constant POOL_ADDRESSES_PROVIDER =
        0x5E52dEc931FFb32f609681B8438A51c675cc232d; // Aave V3 Goerli (already checksummed)
    uint24 constant UNISWAP_POOL_FEE = 500; // 0.05%

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        FlashLoanArbitrage arb = new FlashLoanArbitrage(
            IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER),
            UNISWAP_V3_ROUTER,
            SUSHISWAP_ROUTER,
            USDC,
            DAI,
            UNISWAP_POOL_FEE
        );
        vm.stopBroadcast();
        console2.log("FlashLoanArbitrage deployed at:", address(arb));
    }
}
