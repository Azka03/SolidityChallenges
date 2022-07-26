const hre = require("hardhat");
const ethers = hre.ethers;


async function main() {
  // We get the contract to deploy
  const ZemToken = await hre.ethers.getContractFactory("ERC20Factory");
  const zemtoken = await ZemToken.deploy();

  await zemtoken.deployed();

  await zemtoken.deployToken("D","Den",18);

  const res = await zemtoken.tokenAddresses();
  // console.log("Tokens Deployed on: "+ res)


//   await hre.run("verify:verify", {
//     address: zuzutoken.address,
//     constructorArguments: [],
//   });

  console.log("Contract deployed to:", zemtoken.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
