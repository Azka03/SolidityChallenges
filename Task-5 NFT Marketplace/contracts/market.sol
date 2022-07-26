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
    }

    //List of owners of the NFTs which are on sale (Includes auction params as well)
    struct SaleNFTs {
        address seller; 
        address token;
        uint tokenId;
        address payableToken; //Payment to be done in which token
        bool sold;
        address lastBidder;
        uint heighestBid;
        address winner;
        address royalityReceiver; //Creator of the NFT
        uint royalityFee;
        
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

    // nft(token address) => nft tokenID => Bidders struct 
    mapping (address => mapping(uint => Bidder)) private _bidders;

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

    function setNFTonSale (address _royaltyReciever, address _seller, address _nftToken, uint _nftTokenId, address _payableToken, uint _royalityFee) external { 
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
            seller: _seller, 
            token: _nftToken,
            tokenId: _nftTokenId,
            payableToken: _payableToken,
            sold: false,
            lastBidder: address(0),
            heighestBid: 0,
            winner: address(0),
            royalityReceiver: _royaltyReciever,
            royalityFee: _royalityFee
            // startTime: _startTime,
            // endTime: _endTime
        });

        _NftsList[_nftToken][_nftTokenId] = NFTList({
                onSale: true,
                seller: msg.sender,
                token: _nftToken,
                tokenId: _nftTokenId
        });

        nft.transferFrom(_seller, address(this), _nftTokenId);

        emit onSale (_nftTokenId, _nftToken, msg.sender);
    } 

    function getOnSaleNFT(address _nftToken, uint256 _nftTokenId) public view returns (SaleNFTs memory) {
        return _onSaleNfts[_nftToken][_nftTokenId];
    }

    function placeBid (address _nftToken, address _buyer, uint _price, uint _nftTokenId, address _paymentToken) external payable isListedOnSaleNFT (_nftToken, _nftTokenId) {
        //Checks:
        // -Seller cannot be buyer
        // -Token is on sale
        // -If current bid is higher than previous, replace the bid 
        // -Time, Start time of auction should be less than current time (Auction Started or not)
        // -Time, End time of auction should be greater than current time (Auction Ended or not) 
        // -Bidder has the amount to transfer or not? 

        Token nft = Token(_nftToken);

        require(nft.ownerOf(_nftTokenId)!=_buyer, "Seller cannot be buyer");
        require(_price >=_onSaleNfts[_nftToken][_nftTokenId].heighestBid, "Bid less than highest bid price");
        
         _bidders[_nftToken][_nftTokenId] = Bidder({
            buyer: _buyer,
            nftToken: _nftToken, //nft to be sold 
            nftTokenId: _nftTokenId,
            price: _price,
            paidToken: _paymentToken
        });

        SaleNFTs storage saleNFT = _onSaleNfts[_nftToken][_nftTokenId];
        Bidder storage biddersNFT = _bidders[_nftToken][_nftTokenId];

        ZemToken payToken = ZemToken(biddersNFT.paidToken);
        // console.log("Bidder Address: ", _buyer, "Balance of bidder: ", payToken.balanceOf(biddersNFT.buyer));
        
        payToken.approve(biddersNFT.buyer, payToken.balanceOf(biddersNFT.buyer));

        payToken.transferFrom(biddersNFT.buyer, address(this), _price);
        // console.log(payToken.balanceOf(_buyer));

        if (saleNFT.lastBidder != address(0)) {
            address lastBidder = saleNFT.lastBidder;
            uint lastBidPrice = saleNFT.heighestBid;

            // Transfer back to last bidder
            payToken.approve(address(this), lastBidPrice);

            payToken.transferFrom(address(this), lastBidder, lastBidPrice);
            // console.log(payToken.balanceOf(address(this)));
        }

        // Set new heighest bid price
        saleNFT.lastBidder = _buyer; //address buyer
        saleNFT.heighestBid = _price;

        _buyersList[_nftToken][_buyer]=true;
    }

    function getBidder(address _nftToken, uint256 _nftTokenId) public view returns (Bidder memory) {
        return _bidders[_nftToken][_nftTokenId];
    }

    function updateBid(address _nftToken, address _buyer, uint _price, uint _nftTokenId) external {
        //Checks:
        // -If buyer has already placed a bid?
        // -If update is not equal to the previous bid
        
        require (_buyersList[_nftToken][_buyer], "Bid not placed by specified buyer");

        Bidder storage biddersNFT = _bidders[_nftToken][_nftTokenId];

        require (biddersNFT.price!=_price, "Updating Bid with same price is not allowed");

        ZemToken payToken = ZemToken(biddersNFT.paidToken);
        SaleNFTs storage nftonSale = _onSaleNfts[_nftToken][_nftTokenId];

        payToken.approve(address(this), nftonSale.heighestBid);
        payToken.transferFrom(address(this), _buyer, nftonSale.heighestBid);

        biddersNFT.price=_price;
        nftonSale.heighestBid = _price;
        // console.log(nftonSale.heighestBid);

        payToken.transferFrom(_buyer, address(this), nftonSale.heighestBid);
    }

    function cancelBid(address _nftToken, address _buyer, uint _nftTokenId) external {
        require (_buyersList[_nftToken][_buyer], "Bid not placed by specified buyer");

        Bidder storage biddersNFT = _bidders[_nftToken][_nftTokenId];
        ZemToken payToken = ZemToken(biddersNFT.paidToken);

        SaleNFTs storage nftonSale = _onSaleNfts[_nftToken][_nftTokenId];

        // console.log(payToken.balanceOf(_buyer));
        // console.log(nftonSale.heighestBid);


        payToken.approve(address(this), nftonSale.heighestBid);
        payToken.transferFrom(address(this), _buyer, nftonSale.heighestBid);

        // console.log(payToken.balanceOf(_buyer));

        delete _buyersList[_nftToken][_buyer];
        delete _bidders[_nftToken][_nftTokenId];
        delete _NftsList[_nftToken][_nftTokenId];
        delete _bidders[_nftToken][_nftTokenId];

        nftonSale.heighestBid = 0;
        nftonSale.lastBidder = address(0); 
    }

    function ConcludeAuction(address _nftToken, uint _nftTokenId) external {
        SaleNFTs storage auction = _onSaleNfts[_nftToken][_nftTokenId];
        Bidder storage biddersNFT = _bidders[_nftToken][_nftTokenId];

        _NftsList[_nftToken][_nftTokenId] = NFTList({
                onSale: false,
                seller: msg.sender,
                token: _nftToken,
                tokenId: _nftTokenId
        });

        ZemToken payToken = ZemToken(biddersNFT.paidToken);
        Token nft = Token(auction.token);

        auction.sold=true;
        auction.winner= auction.lastBidder;
        uint totalPrice = auction.heighestBid;

        // console.log("Total Sale Price", totalPrice);

        // console.log("Balance before concluding: ", payToken.balanceOf(address(this)));
        console.log("Creator: ", auction.royalityReceiver);
        console.log("Seller: ", auction.seller);

        payToken.approve(address(this), auction.heighestBid);
        console.log("Fee: ", auction.royalityFee);
        if(auction.royalityReceiver!=auction.seller){
            console.log("Secondary Sale");
            uint creatorRoyalty = (totalPrice)/auction.royalityFee;
            console.log("Creator's Balance before: ", payToken.balanceOf(auction.royalityReceiver));
            console.log("Seller's  Balance before: ", payToken.balanceOf(auction.seller));
            console.log("Creator Royality Fee", creatorRoyalty);
            payToken.transferFrom(address(this), auction.royalityReceiver, creatorRoyalty);
            console.log("Creator's Balance after concluding: ", payToken.balanceOf(auction.royalityReceiver));
            console.log("Seller's profit: ", totalPrice-creatorRoyalty);

            payToken.transferFrom(address(this), auction.seller, totalPrice-creatorRoyalty);
            console.log("Seller's after concluding: ", payToken.balanceOf(auction.seller));

        }
        else{
            console.log("First Sale");
            payToken.transferFrom(address(this), auction.seller, totalPrice);
        }
        // Transfer to auction creator
        // console.log("Balance after concluding: ", payToken.balanceOf(address(this)));

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);

        console.log("New Owner: ", nft.ownerOf(_nftTokenId));
    }
}