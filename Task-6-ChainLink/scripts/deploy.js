const hre = require("hardhat");
const ethers = hre.ethers;


async function main() {
  // We get the contract to deploy
  const chainLink = await hre.ethers.getContractFactory("APIConsumer");
  const ChainLink = await chainLink.deploy();

  await ChainLink.deployed();

  let res = await ChainLink.requestVolumeData();
  console.log(res);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
