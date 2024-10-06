// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ConstantProductAMM {
    ERC20 public token;
    ERC20 public WETH;
    uint256 public reserveToken;
    uint256 public reserveWETH;

    constructor(address _token, address _WETH) {
        token = ERC20(_token);
        WETH = ERC20(_WETH);
    }

    function addLiquidity(uint256 tokenAmount, uint256 WETHAmount) public {
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        require(WETH.transferFrom(msg.sender, address(this), WETHAmount), "WETH transfer failed");

        reserveToken += tokenAmount;
        reserveWETH += WETHAmount;
    }

    function removeLiquidity(uint256 liquidity) public {
        uint256 tokenAmount = (liquidity * reserveToken) / totalLiquidity();
        uint256 WETHAmount = (liquidity * reserveWETH) / totalLiquidity();

        reserveToken -= tokenAmount;
        reserveWETH -= WETHAmount;

        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
        require(WETH.transfer(msg.sender, WETHAmount), "WETH transfer failed");
    }

    function swapTokenForWETH(uint256 tokenAmount) public {
        uint256 WETHOut = getAmountOut(tokenAmount, reserveToken, reserveWETH);

        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        reserveToken += tokenAmount;
        reserveWETH -= WETHOut;

        require(WETH.transfer(msg.sender, WETHOut), "WETH transfer failed");
    }

    function swapWETHForToken(uint256 WETHAmount) public {
        uint256 tokenOut = getAmountOut(WETHAmount, reserveWETH, reserveToken);

        require(WETH.transferFrom(msg.sender, address(this), WETHAmount), "WETH transfer failed");
        reserveWETH += WETHAmount;
        reserveToken -= tokenOut;

        require(token.transfer(msg.sender, tokenOut), "Token transfer failed");
    }

    function getAmountOut(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }

    function totalLiquidity() public view returns (uint256) {
        return reserveToken * reserveWETH;
    }
}
