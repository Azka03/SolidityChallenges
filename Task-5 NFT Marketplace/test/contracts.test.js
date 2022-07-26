const { expect } = require("chai");
const { ethers } = require("hardhat");
const chai = require("chai");
const hre = require("hardhat");

describe("Market Deployment", async function () {

    let contractFactory;
    let marketContract;
    let erc20Factory;
    let erc721Factory;
    let erc20Token;
    let tkAddr;
    let nftAddr;
    let nftOwner;
    let nft;
    const fee=10;

    beforeEach(async () => {

        //list of the accounts in the node we're connected to, which in this case is Hardhat Network, and only keeping the first four here.
        [_seller, _buyer, _buyer2] = await ethers.getSigners(); //Ethereum account(s)

        //Deploying contracts
        contractFactory = await ethers.getContractFactory("Market"); // used to deploy new smart contracts
        contractFactory2 = await ethers.getContractFactory("ERC20Factory"); 
        contractFactory3 = await ethers.getContractFactory("ERC721Factory"); 
        contractFactory4 = await ethers.getContractFactory("ZemToken"); 
        contractFactory5 = await ethers.getContractFactory("Token");

        marketContract = await contractFactory.deploy(); //deployment will be started
        await marketContract.deployed();

        erc20Factory = await contractFactory2.deploy(); 
        await erc20Factory.deployed();

        erc721Factory = await contractFactory3.deploy();
        await erc721Factory.deployed();

        erc20Token = await contractFactory4.deploy("Z","Zyloric",18); //deployment will be started
        await erc20Token.deployed();

        nft = await contractFactory5.deploy("C", "CiproxNFT", 3);
        await nft.deployed();
        

        await erc20Factory.deployToken("T","Temzol",18, ethers.utils.parseUnits("200000", 18));   //Deploy ERC20 Token
        await erc20Token.transfer(_buyer.address, ethers.utils.parseUnits("1000", 18));
        await erc20Token.transfer(_buyer2.address, ethers.utils.parseUnits("2000", 18));

        await erc20Token.approve(_buyer.address, ethers.utils.parseUnits("1000", 18));
        await erc20Token.approve(_buyer2.address, ethers.utils.parseUnits("2000", 18));        

        // const res22 = await erc20Token.balanceOf(_buyer.address);
        // console.log("BUYER BALANCE BEFORE: ", _buyer.address, "BALANCEE: ", res22)

        tkAddr= await erc20Factory.tokenAddresses(); //payable token
        // console.log("Token Address: ", tkAddr[0]);
        // console.log("ERC wala: ", erc20Token.address)

        await erc721Factory.deployToken("L","LefloxNFT",1);   //NFT on sale
        await erc721Factory.deployToken("T","TemzolNFT",2);   //NFT on sale

        nftAddr= await erc721Factory.tokenAddresses(); //NFT on sale ka address
        // console.log(nftAddr[0]);

        await nft.mint(_seller.address, 2);
        nftOwner = await nft.ownerOf(2);
        // console.log("NFT OWNER", nftOwner);
    })

    it("Should show successful deployment", async function(){
        console.log("Success")
    });

    it("Should put NFT on sale", async function(){

        // nftOwner = await nft.ownerOf(2);
        // console.log("NFT OWNER", nftOwner);

        await marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[0], 1, tkAddr[0], fee);

        // const res1 = await contract3.ownerOf(1);
        // console.log("Owner: ", res1);  
        // console.log(owner.address);
        // console.log(nftAddr[1]);
        const res = await marketContract.getOnSaleNFT(nftAddr[0],1);
        // console.log(res);
    });

    it("Should not put NFT on sale", async function(){
 
        await expect(marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[1], 1, tkAddr[0], fee)).to.be.revertedWith("Only Owner can forward the request to put NFT on sale");
        
    });

    it("Should place bid", async function(){
        
        await erc20Token.transfer(_buyer.address, ethers.utils.parseUnits("1000", 18))


        await marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[0], 1, tkAddr[0], fee);
        // console.log("TOKEN ADRESS TEST**: ", tkAddr[0]);

        const res2 = await erc20Token.balanceOf(_buyer.address);
        // console.log("ACCOUNT: ", _buyer.address, "BALANCEE: ", res2)
        const res= await marketContract.placeBid(nftAddr[0], _buyer.address, 10, 1, erc20Token.address);
        // console.log(res);
    });

    it("Should place 2 bids", async function(){
        
        // await erc20Token.transfer(_buyer.address, ethers.utils.parseUnits("1000", 18))


        await marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[0], 1, tkAddr[0], fee);
        console.log("TOKEN ADRESS TEST**: ", tkAddr[0]);

        await erc20Token.approve(_buyer2.address, erc20Token.balanceOf(_buyer2.address));
        console.log("Second Bidder: ", await erc20Token.balanceOf(_buyer2.address));
        console.log("ALLOWED: ",await erc20Token.allowance(_seller.address, _buyer2.address));

        const res2 = await erc20Token.balanceOf(_buyer.address);
        // console.log("ACCOUNT: ", _buyer.address, "BALANCEE: ", res2)
        const res= await marketContract.placeBid(nftAddr[0], _buyer.address, 10, 1, erc20Token.address);
        
        const res3= await marketContract.placeBid(nftAddr[0], _buyer2.address, 20, 1, erc20Token.address);

        // console.log(res);
    });

    it("Should place update bid", async function(){
        
        await marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[0], 1, tkAddr[0], fee);
        // console.log("TOKEN ADRESS TEST**: ", tkAddr[0]);

        const res2 = await erc20Token.balanceOf(_buyer.address);
        console.log("ACCOUNT: ", _buyer.address, "BALANCEE: ", res2)
        const res= await marketContract.placeBid(nftAddr[0], _buyer.address, 10, 1, erc20Token.address);
        const res23 = await marketContract.updateBid(nftAddr[0], _buyer.address, 5, 1);
    });

    it("Should place not update bid", async function(){
        
        await marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[0], 1, tkAddr[0], fee);
        // console.log("TOKEN ADRESS TEST**: ", tkAddr[0]);

        const res2 = await erc20Token.balanceOf(_buyer.address);
        // console.log("ACCOUNT: ", _buyer.address, "BALANCEE: ", res2)
        const res= await marketContract.placeBid(nftAddr[0], _buyer.address, 10, 1, erc20Token.address);
        await expect(marketContract.updateBid(nftAddr[0], _buyer2.address, 5, 1)).to.be.revertedWith("Bid not placed by specified buyer");

    });

    it("Should cancel bid", async function(){
        
        await marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[0], 1, tkAddr[0], fee);
        // console.log("TOKEN ADRESS TEST**: ", tkAddr[0]);

        const res2 = await erc20Token.balanceOf(_buyer.address);
        // console.log("ACCOUNT: ", _buyer.address, "BALANCEE: ", res2)
        const res= await marketContract.placeBid(nftAddr[0], _buyer.address, 10, 1, erc20Token.address);
        const res23 = await marketContract.cancelBid(nftAddr[0], _buyer.address, 1);
    });

    it("Should conclude Auction", async function(){
        await marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[0], 1, tkAddr[0], fee);
        // console.log("TOKEN ADRESS TEST**: ", tkAddr[0]);

        const res2 = await erc20Token.balanceOf(_buyer.address);
        // console.log("ACCOUNT: ", _buyer.address, "BALANCEE: ", res2)
        const res= await marketContract.placeBid(nftAddr[0], _buyer.address, 10, 1, erc20Token.address);
        const res23 = await marketContract.ConcludeAuction(nftAddr[0], 1);
    });

    it("Should conclude Auction and pay royality fee to creator", async function(){
        await marketContract.setNFTonSale(nftOwner, _seller.address, nftAddr[0], 1, tkAddr[0], fee);
        // console.log("TOKEN ADRESS TEST**: ", tkAddr[0]);

        const res2 = await erc20Token.balanceOf(_buyer.address);
        // console.log("ACCOUNT: ", _buyer.address, "BALANCEE: ", res2)
        const res= await marketContract.placeBid(nftAddr[0], _buyer.address, 10, 1, erc20Token.address);
        const res23 = await marketContract.ConcludeAuction(nftAddr[0], 1);

        await marketContract.setNFTonSale(nftOwner, _buyer.address, nftAddr[0], 1, tkAddr[0], fee);
        const res22= await marketContract.placeBid(nftAddr[0], _seller.address, 10, 1, erc20Token.address);
        const res233 = await marketContract.ConcludeAuction(nftAddr[0], 1);
    });
});