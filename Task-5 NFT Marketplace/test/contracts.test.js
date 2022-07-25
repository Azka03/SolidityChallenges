const { expect } = require("chai");
const { ethers } = require("hardhat");
const chai = require("chai");
const hre = require("hardhat");

describe("Market Deployment", async function () {

    let contractFactory;
    let marketContract;
    let FERC20Contract;
    let FERC721Contract;
    let ERC20Token;
    let tkAddr;
    let nftAddr;

    beforeEach(async () => {
        contractFactory = await ethers.getContractFactory("Market"); // used to deploy new smart contracts
        contractFactory2 = await ethers.getContractFactory("ERC20Factory"); // used to deploy new smart contracts
        contractFactory3 = await ethers.getContractFactory("ERC721Factory"); // used to deploy new smart contracts
        contractFactory4 = await ethers.getContractFactory("ZemToken"); // used to deploy new smart contracts

        marketContract = await contractFactory.deploy(); //deployment will be started
        await marketContract.deployed();

        FERC20Contract = await contractFactory2.deploy(); //deployment will be started
        await FERC20Contract.deployed();

        FERC721Contract = await contractFactory3.deploy(); //deployment will be started
        await FERC721Contract.deployed();

        ERC20Token = await contractFactory4.deploy("Z","Zyloric",18); //deployment will be started
        await ERC20Token.deployed();
        
       //list of the accounts in the node we're connected to, which in this case is Hardhat Network, and only keeping the first four here.
        [_seller, _buyer] = await ethers.getSigners(); //Ethereum account(s)


        await FERC20Contract.deployToken("T","Temzol",18, ethers.utils.parseUnits("200000", 18));   //Deploy ERC20 Token
        await ERC20Token.transfer(_buyer.address, ethers.utils.parseUnits("1000", 18))


        const res22 = await ERC20Token.balanceOf(_buyer.address);
        // console.log("BUYER BALANCE BEFORE: ", _buyer.address, "BALANCEE: ", res22)

        tkAddr= await FERC20Contract.tokenAddresses(); //payable token
        // console.log(tkAddr[0]);

        await FERC721Contract.deployToken("L","LefloxNFT",1);   //NFT on sale
        await FERC721Contract.deployToken("T","TemzolNFT",2);   //NFT on sale


        nftAddr= await FERC721Contract.tokenAddresses(); //NFT on sale ka address
        // console.log(nftAddr[0]);
    })

    it("Should show successful deployment", async function(){
        console.log("Success")
    });

    it("Should put NFT on sale", async function(){

        await marketContract.setNFTonSale(_seller.address, nftAddr[0], 1, tkAddr[0]);
        // const res1 = await contract3.ownerOf(1);
        // console.log("Owner: ", res1);  
        // console.log(owner.address);
        // console.log(nftAddr[1]);
        const res = await marketContract.getOnSaleNFT(nftAddr[0],1);
        // console.log(res);
    });

    it("Should not put NFT on sale", async function(){
 
        await expect(marketContract.setNFTonSale(_seller.address, nftAddr[1], 1, tkAddr[0])).to.be.revertedWith("Only Owner can forward the request to put NFT on sale");
        
    });

    it("Should place bid", async function(){
        
        await ERC20Token.transfer(_buyer.address, ethers.utils.parseUnits("1000", 18))


        await marketContract.setNFTonSale(_seller.address, nftAddr[0], 1, tkAddr[0]);
        // console.log("TOKEN ADRESS TEST**: ", tkAddr[0]);

        const res2 = await ERC20Token.balanceOf(_buyer.address);
        // console.log("ACCOUNT: ", _buyer.address, "BALANCEE: ", res2)
        const res= await marketContract.placeBid(nftAddr[0], _buyer.address, 10, 1);
        // console.log(res);
    });

   
});