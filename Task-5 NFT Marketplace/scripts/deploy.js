const hre = require("hardhat");
const ethers = hre.ethers;


async function main() {
  // We get the contract to deploy
  const NFT = await hre.ethers.getContractFactory("ERC721Factory");
  const nft = await NFT.deploy();

  await nft.deployed();

  let deployToken = await nft.deployToken("D","Den");
  await deployToken.wait(); //wait for the transaction on blockchain to complete, different from await/async

  const res = await nft.tokenAddresses();
  console.log("Tokens Deployed on: "+ typeof(res))


  // await hre.run("verify:verify", {
  //   address: nft.address,
  //   constructorArguments: [],
  // });

  await hre.run("verify:verify", {
    address: res.toString(),
    constructorArguments: ["D","Den"],
  });

  // console.log("Contract deployed to:", nft.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
