import { ethers,upgrades } from "hardhat";

async function main() {

  const IUniSwapFactory = await ethers.getContractFactory("PayLinkUniSwap");
  //usdt , matic , router , quoter
  const IUniSwap = await upgrades.deployProxy(IUniSwapFactory,["0xc2132D05D31c914a87C6611C10748AEb04B58e8F","0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0","0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad","0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6"],{ initializer: 'initialize' });

  await IUniSwap.deployed();

  console.log(
    `IUniSwap with deployed to ${IUniSwap.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
