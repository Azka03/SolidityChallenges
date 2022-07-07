const { expect } = require("chai");
const { ethers } = require("hardhat");
const chai = require("chai");
const hre = require("hardhat");

describe("ZuzuToken Deployment", async function () {

    let contractFactory;
    let contract;
    let owner;
    let addr1;
    let addr2;
    let addr3;

    beforeEach(async () => {
        contractFactory = await ethers.getContractFactory("ERC20Factory"); // used to deploy new smart contracts
        contract = await contractFactory.deploy(); //deployment will be started
        await contract.deployed();
       //list of the accounts in the node we're connected to, which in this case is Hardhat Network, and only keeping the first three here.
        [owner, addr1, addr2, addr3] = await ethers.getSigners(); //Ethereum account(s)
    });

    it("Should show successful deployment", async function(){
        console.log("Success")
    });

    it("Should deploy token(s)", async function(){
        await contract.deployToken("T","Temzol",18);
        // console.log("DEPLOY TOKEN")
    });

    it("Should return addresses/tokend", async function(){
      
        await contract.deployToken("T","Temzol",18);
        await contract.deployToken("Z","Zem",19);

        const res= await contract.tokenAddresses();
        console.log(res);
        // expect(ethers.utils.formatEther(balance)).to.equal('1000000.0') 
    });

    it("Should return an address is not whitelisted", async function(){
        await expect(contract.withdrawTokens(owner.address, addr1.address, 1000)).to.be.revertedWith("Address not whiteListed");
    });

    it("Should return withdrawl more than 100000 Tokens is not permitted", async function(){
        await contract.setWhiteListed(owner.address, true);
        await contract.deployToken("Z","Zem",19);

        const resp= await contract.tokenAddresses();

        await expect(contract.withdrawTokens(resp[0], addr1.address, 200000)).to.be.revertedWith("Withdraw of maximum 100000 tokens is allowed per transaction");
    });

    it("Should return an address is already added in whitelisted record", async function(){
       
        const resp=await contract.getWhiteListed(addr3.address);
        expect(resp).to.equal(false);
        await contract.setWhiteListed(addr3.address, true);

        await expect(contract.setWhiteListed(addr3.address, true)).to.be.revertedWith("This state already exists");
        
        const resp2=await contract.getWhiteListed(addr3.address);
        expect(resp2).to.equal(true);

    });

    it("Should run withdraw func", async function(){
        await contract.setWhiteListed(owner.address, true);
        await contract.deployToken("Z","Zem",19);

        const resp= await contract.tokenAddresses();
        // console.log(resp);

        await contract.withdrawTokens(resp[0], addr1.address, 1000);

        // console.log(res);
    });

    it("Should return balance of all", async function(){
        await contract.setWhiteListed(owner.address, true);
        await contract.deployToken("Z","Zem",18);
        await contract.deployToken("D","Dan",18);

        const res=await contract.balanceOfAll(owner.address);

        // console.log(res[0], res[1]);
    });

   
});