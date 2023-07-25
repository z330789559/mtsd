import { ethers,upgrades } from "hardhat";

async function main() {

  const Deposit = await ethers.getContractFactory("Deposit");
  //cold address op address signer address  
  const DepositContract = await upgrades.deployProxy(Deposit,["0xdF0cb008541F5023d5500c6c195a5501b53FD599","0x1c1860870a362c3B7eD3F278347c4F20B1eA4953","0xdaf15Ccc4449e94B9eE904aF02E63F3469Bb94A1"],{ initializer: 'initialize' });

  await DepositContract.deployed();

  console.log(
    `IUniSwap with deployed to ${DepositContract.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
