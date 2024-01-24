
import { time, loadFixture, } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

// const  USDT_ADDRESS = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT contract address on Ethereum mainnet
// const MATIC_ADDRESS = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0; // MATIC contract address on Ethereum mainnet
// const QUICKSWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // QuickSwap router contract address on Ethereum mainnet

const  USDC_ADDRESS = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e; // USDC contract address on Ethereum mainnet
const   USDT_ADDRESS = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT contract address on Ethereum mainnet
const MATIC_ADDRESS = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // MATIC contract address on Ethereum mainnet
const QUICKSWAP_ROUTER_ADDRESS = 0xe592427a0aece92de3edee1f18e0157c05861564; // QuickSwap router contract address on Ethereum mainnet


// const USDT =0xc2132D05D31c914a87C6611C10748AEb04B58e8F



async function deployOneYearLockFixture() {
    const ONE_ETH =ethers.utils.parseEther("1");
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_WEEK= 6* 24 * 60 * 60;
    const [owner, otherAccount1, otherAccount2, otherAccount3] = await ethers.getSigners();
    return { owner, otherAccount1, otherAccount2, otherAccount3, ONE_ETH, ONE_YEAR_IN_SECS, ONE_WEEK };
    }
      describe("IPaySwap", function () {


    describe("Deployment", function () {

    });


});
