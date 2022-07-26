const hre = require("hardhat");
const ethers = hre.ethers;


async function main() {
  // We get the contract to deploy
  const ZuzuToken = await hre.ethers.getContractFactory("ZuzuToken");
  const zuzutoken = await ZuzuToken.deploy();

  await zuzutoken.deployed();

//   await hre.run("verify:verify", {
//     address: zuzutoken.address,
//     constructorArguments: [],
//   });

  console.log("Contract deployed to:", zuzutoken.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
