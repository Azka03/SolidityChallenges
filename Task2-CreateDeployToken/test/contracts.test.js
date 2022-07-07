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

    beforeEach(async () => {
        contractFactory = await ethers.getContractFactory("ZuzuToken"); // used to deploy new smart contracts
        contract = await contractFactory.deploy(); //deployment will be started
        await contract.deployed();
       //list of the accounts in the node we're connected to, which in this case is Hardhat Network, and only keeping the first one.
        [owner, addr1, addr2] = await ethers.getSigners(); //Ethereum account(s)
        // console.log(owner);
        // console.log(addr1);
        // await contract.transfer(addr1.address, 10); 

    });

    it("Should show successful deployment", async function(){
        console.log("Success")
    });


    it("Should show total balance of owner", async function(){
        let x= await contract.decimals();
        console.log(x);
        const balance= await contract.balanceOf(owner.address);
        console.log(balance)
        expect(ethers.utils.formatEther(balance)).to.equal('1000000.0') 

    });

    it("Should return total supply", async function(){
        let x= await contract.decimals();
        console.log(x);
        const balance= await contract.totalSupply();
        console.log(balance)
        expect(ethers.utils.formatEther(balance)).to.equal('1000000.0') 
    });

    it("Should return allowed amount of tokens for spender to spend", async function(){
        const res=await contract.allowance(owner.address, addr1.address);
        console.log(res);
        expect(res).to.equal(0);
    });

    it("Should transfer from owner to another account", async function(){
        await contract.transfer(addr1.address, 10);
        // console.log(res);
        const balance= await contract.balanceOf(addr1.address);
        console.log(balance)
        expect(balance).to.equal(10);
    });

    it("Should not transfer from owner to another account", async function(){
        // const res=await contract.transfer(addr1.address, 10000000000000);
        // console.log(res);



        await contract.transfer(addr1.address, 100);
        // console.log(res);
        const balance= await contract.balanceOf(addr1.address);
        console.log(balance)
        expect(balance).to.equal(100);

        // await contract.connect(addr1).transfer(addr2.address, 1000)
        // const balance2= await contract.balanceOf(addr1.address);
        // console.log("BALLLL: " + balance2)
        // expect(balance2).to.equal(0);

        await expect(contract.connect(addr1).transfer(addr2.address, 1000)).to.be.revertedWith("Account does not have entered amount of tokens")
    });

    it("Should not send tokens due to less balance", async function(){ 
        await expect(contract.transferFrom(addr1.address,addr2.address,30)).to.be.revertedWith("Account does not have entered amount of tokens")
        // const res=await contract.mulDiv(2,6,0);  
    });

    it("Should not send tokens due to no allowance", async function(){
        await contract.transfer(addr1.address, 10);

        const balance= await contract.balanceOf(addr1.address);
        console.log(balance)

        await expect(contract.transferFrom(addr1.address,addr2.address,10)).to.be.revertedWith("Not approved to send this amount of tokens")

    });

    it("Should send tokens from third party", async function(){
        await contract.transfer(addr1.address, 10);

        const balance= await contract.balanceOf(addr1.address);
        console.log(balance)

        const resp= await contract.approve(addr1.address, 10);
        // console.log(resp);

        const res=await contract.allowance(owner.address, addr1.address);
        console.log("***ALLOWED***"+res);

        const resTrans= await contract.transferFrom(addr1.address,addr2.address,8);
        // const res = await expect(contract.transferFrom(addr1.address,addr2.address,40)).to.be.revertedWith("Not approved to send this amount of tokens")
        // console.log(resTrans);

        const balance2= await contract.balanceOf(addr1.address);
        console.log("UPDATED BALANCE "+balance2)

        const balance3= await contract.balanceOf(addr2.address);
        console.log("UPDATED BALANCE of ADDR-2 "+balance3)
    });
});