import { ethers } from "hardhat";

async function main() {

  const MintableERC20 = await ethers.getContractFactory("MintableERC20");
  const Mintable = await MintableERC20.deploy("USDT","USDT",6);

  await Mintable.deployed();

  console.log(
    `Lock with deployed to ${Mintable.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
