// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./ERC721Factory.sol"; //Factory ERC721
import "./ERC20Factory.sol"; //Factory ERC20
import "./token.sol"; //Standard functions ERC721
import "./zem.sol"; //Standard functions ERC20

import "hardhat/console.sol"; //console for debugging

contract Market {
   
    //which NFTs are on sale (List of NFTs)
    struct NFTList{
        bool onSale;
        address seller;
        address token;
        uint tokenId;
        // TokenStatus status;
    }

    //List of owners of the NFTs which are on sale (Includes auction params as well)
    struct SaleNFTs {
        address seller;
        address token;
        uint tokenId;
        address payableToken; //konse token mein payment ho 
        // uint price; because of auction, price buyer btaye ga 
        bool sold;
        // uint initialPrice; ask if there is any initial price?
        // uint minBid;
        address lastBidder;
        uint heighestBid;
        // address buyer; //added for update func
        address winner;
        // uint startTime; //Do it later
        // uint endTime;
    }

    //List of bidders who bid on certain NFT
    struct Bidder {
        address buyer;
        address nftToken; //nft to be sold 
        uint nftTokenId;
        uint price; 
        address paidToken;
    }

    // nft address => tokenId => NFTList struct 
    mapping(address => mapping(uint => NFTList)) private _NftsList;

    // nft => tokenId => SaleNFT struct
    mapping(address => mapping(uint => SaleNFTs)) private _onSaleNfts;

    // nft(token address) => bidder address => bid price 
    mapping (address => mapping(address => Bidder)) private _bidders;

    //nft(token address) => bidder address => placed a bid or not
    mapping (address => mapping (address => bool)) private _buyersList;
      
    event onSale(uint tokenId, address token, address seller);
    event Update(uint tokenId, address token, address buyer, uint price);
    event Cancel(address buyer, uint price);

    modifier isListedOnSaleNFT (address _nftToken, uint256 _nftTokenId) {
        NFTList memory listedNFT = _NftsList[_nftToken][_nftTokenId];
        require(listedNFT.onSale, "Not Listed");
        _;
    }

    function setNFTonSale (address _seller, address _nftToken, uint _nftTokenId, address _payableToken) external { 
        //Checks:
        //See if the token put on sale is done by the owner of the NFT 
        //End time should be greater than start time
        //Check if already on sale?
            
        Token nft = Token(_nftToken);
        // console.log("Owner of token: ", nft.ownerOf(_nftTokenId));

        NFTList memory listedNFT = _NftsList[_nftToken][_nftTokenId];
        require(!listedNFT.onSale, "Already on sale");

        require(_seller == nft.ownerOf(_nftTokenId), "Only Owner can forward the request to put NFT on sale");

        _onSaleNfts[_nftToken][_nftTokenId] = SaleNFTs({
            seller: msg.sender, //address seller
            token: _nftToken,
            tokenId: _nftTokenId,
            payableToken: _payableToken,
            sold: false,
            lastBidder: address(0),
            heighestBid: 0,
            winner: address(0)
            // startTime: _startTime,
            // endTime: _endTime
        });

        _NftsList[_nftToken][_nftTokenId] = NFTList({
                onSale: true,
                seller: msg.sender,
                token: _nftToken,
                tokenId: _nftTokenId
        });

        emit onSale (_nftTokenId, _nftToken, msg.sender);
    } 

    function getOnSaleNFT(address _nftToken, uint256 _nftTokenId) public view returns (SaleNFTs memory) {
        return _onSaleNfts[_nftToken][_nftTokenId];
    }

    function placeBid (address _nftToken, address _buyer, uint _price, uint _nftTokenId) external payable isListedOnSaleNFT (_nftToken, _nftTokenId) {
        //Checks:
        // -Seller cannot be buyer
        // -Token is on sale
        // -If current bid is higher than previous, replace the bid  (DONE)
        // -Time, Start time of auction should be less than current time (Auction Started or not)
        // -Time, End time of auction should be greater than current time (Auction Ended or not) 
        // -Bidder has the amount to transfer or not? 

        Token nft = Token(_nftToken);
        require(nft.ownerOf(_nftTokenId)!=_buyer, "Seller cannot be buyer");

        require(_price >=_onSaleNfts[_nftToken][_nftTokenId].heighestBid, "less than highest bid price");
        
        SaleNFTs storage saleNFT = _onSaleNfts[_nftToken][_nftTokenId];
        IERC20 payToken = IERC20(saleNFT.payableToken);
        // console.log(saleNFT.payableToken, "TOKEN PAYABLE");
        // console.log("BUYER Contract: ", _buyer, "Balance: ", payToken.balanceOf(_buyer));

        payToken.transferFrom(_buyer, address(this), _price);
        // console.log("buyer: ", _buyer);
        // console.log("address: ", address(this));
        // console.log(payToken.balanceOf(address(this)));

        if (saleNFT.lastBidder != address(0)) {
            address lastBidder = saleNFT.lastBidder;
            uint lastBidPrice = saleNFT.heighestBid;

            // Transfer back to last bidder
            payToken.transferFrom(address(this), lastBidder, lastBidPrice);
        }

        nft.transferFrom(address(this), saleNFT.lastBidder, saleNFT.tokenId);


        // Set new heighest bid price
        saleNFT.lastBidder = msg.sender; //address buyer
        saleNFT.heighestBid = _price;

        // _bidPrices[_nftToken][_buyer]=_price;
        _buyersList[_nftToken][_buyer]=true;
    }

    function updateBid(address _nftToken, address _buyer, uint _price, uint _nftTokenId) external returns (uint){
        //Checks:
        // -If buyer has already placed a bid?
        // -If update is not equal to the previous bid
        
        require (_buyersList[_nftToken][_buyer], "Bid not placed by specified buyer");

        SaleNFTs storage saleNFT = _onSaleNfts[_nftToken][_nftTokenId];
        IERC20 payToken = IERC20(saleNFT.payableToken);

        SaleNFTs storage nft = _onSaleNfts[_nftToken][_nftTokenId];

        payToken.transferFrom(address(this), _buyer, nft.heighestBid);


        nft.heighestBid = _price;

        payToken.transferFrom(_buyer, address(this), nft.heighestBid);
    }

    function cancelBid(address _nftToken, address _buyer, uint _nftTokenId) external {
        require (!_buyersList[_nftToken][_buyer], "Bid not placed by specified buyer");

        delete _buyersList[_nftToken][_buyer];
        delete _NftsList[_nftToken][_nftTokenId];
        delete _bidders[_nftToken][_buyer];
    }

    function ConcludeAuction(address _nftToken, uint _nftTokenId) external {
        SaleNFTs storage auction = _onSaleNfts[_nftToken][_nftTokenId];
        IERC20 payToken = IERC20(auction.payableToken);
        IERC721 nft = IERC721(auction.token);

        auction.sold=true;
        auction.winner= auction.lastBidder;
        uint totalPrice = auction.heighestBid;

        // Transfer to auction creator
        payToken.transferFrom(auction.lastBidder, auction.seller, totalPrice);

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);
    }

}