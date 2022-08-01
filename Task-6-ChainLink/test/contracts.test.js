const { expect } = require("chai");
const { ethers } = require("hardhat");
const chai = require("chai");
const hre = require("hardhat");

describe("ChainLink", async function () {

    let contractFactory;
    let contract;

    beforeEach(async () => {

        //list of the accounts in the node we're connected to, which in this case is Hardhat Network, and only keeping the first four here.
        // [owner, addr1, addr2] = await ethers.getSigners(); //Ethereum account(s)

        //Deploying contracts
        contractFactory = await ethers.getContractFactory("APIConsumer"); // used to deploy new smart contracts

        contract = await contractFactory.deploy(); //deployment will be started
        await contract.deployed();
    })

    it("Should show successful deployment", async function(){
        console.log("Success")
    });

    it("Should display BTC in USD", async function(){

        const res = await contract.requestVolumeData();
       
        console.log(res);

    });
});