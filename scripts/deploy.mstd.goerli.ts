import { ethers,upgrades } from "hardhat";

async function main() {

  const MTSDFactory = await ethers.getContractFactory("MTSD");
  //cold address op address signer address  
  const mtsd = await upgrades.deployProxy(MTSDFactory,[],{ initializer: 'initialize' });

  await mtsd.deployed();

  console.log(
    `mtsd with deployed to ${mtsd.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
