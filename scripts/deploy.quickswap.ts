import { ethers,upgrades } from "hardhat";

async function main() {

  const IPaySwapFactory = await ethers.getContractFactory("IPaySwap");
  //usdt , matic , router , quoter
  const IPaySwap = await upgrades.deployProxy(IPaySwapFactory,[],{ initializer: 'initialize' });

  await IPaySwap.deployed();

  console.log(
    `IUniSwap with deployed to ${IPaySwap.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
