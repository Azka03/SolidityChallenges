// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./ERC721Factory.sol"; //Factory ERC721
import "./ERC20Factory.sol"; //Factory ERC20
import "./token.sol"; //Standard functions ERC721
import "./zem.sol"; //Standard functions ERC20

import "hardhat/console.sol"; //console for debugging

contract Market {
    //which NFTs are on sale (List of NFTs)
    //TODO change naming
    // struct Nft {
    //     bool onSale;
    //     address seller;
    //     address token;
    //     uint tokenId;
    // }
    //TODO change naming

    //List of owners of the NFTs which are on sale (Includes auction params as well)
    struct Nft {
        address seller;
        address token;
        uint256 tokenId;
        address payableToken; //Payment to be done in which token
        bool onSale;
        bool sold;
        address lastBidder;
        uint256 heighestBid;
        address winner;
        address royalityReceiver; //Creator of the NFT
        uint256 royalityFee;

        // uint startTime; //Do it later
        // uint endTime;
    }

    //TODO change naming
    //List of bidders who bid on certain NFT
    struct Bid {
        address buyer;
        address nftToken; //nft to be sold
        uint256 nftTokenId;
        uint256 price;
        address paidToken;
    }

    // // nft address => tokenId => NFTList struct
    // mapping(address => mapping(uint => Seller)) private _NftsList;
    //TODO change naming

    // nft => tokenId => SaleNFT struct
    mapping(address => mapping(uint256 => Nft)) private nftData;

    // nft(token address) => nft tokenID => Bids struct
    mapping(address => mapping(uint256 => Bid)) private bidData;

    //nft(token address) => bidder address => placed a bid or not
    mapping(address => mapping(address => bool)) private biddersData;

    event OnSale(uint256 tokenId, address token, address seller);
    event Updated(uint256 tokenId, address token, address buyer, uint256 price);
    event Cancelled(address buyer, address token, uint256 tokenId);

    modifier isListedOnSaleNft(address _nftToken, uint256 _nftTokenId) {
        // NFTList memory listedNFT = _NftsList[_nftToken][_nftTokenId];
        // require(listedNFT.onSale, "Not Listed");

        Nft memory listedNFT = nftData[_nftToken][_nftTokenId];
        require(listedNFT.onSale, "Not Listed");
        _;
    }

    function setNFTonSale(
        address _royaltyReciever,
        address _seller,
        address _nftToken,
        uint256 _nftTokenId,
        address _payableToken,
        uint256 _royalityFee
    ) external {
        //Checks:
        //See if the token put on sale is done by the owner of the NFT
        //End time should be greater than start time
        //Check if already on sale?

        Token nft = Token(_nftToken);
        // console.log("Owner of token: ", nft.ownerOf(_nftTokenId));

        // NFTList memory listedNFT = _NftsList[_nftToken][_nftTokenId];
        Nft memory listedNft = nftData[_nftToken][_nftTokenId];

        require(!listedNft.onSale, "Already on sale");
        require(
            _seller == nft.ownerOf(_nftTokenId),
            "Only Owner can forward the request to put NFT on sale"
        );

        nftData[_nftToken][_nftTokenId] = Nft({
            seller: _seller,
            token: _nftToken,
            tokenId: _nftTokenId,
            payableToken: _payableToken,
            onSale: true,
            sold: false,
            lastBidder: address(0),
            heighestBid: 0,
            winner: address(0),
            royalityReceiver: _royaltyReciever,
            royalityFee: _royalityFee
            // startTime: _startTime,
            // endTime: _endTime
        });

        // _NftsList[_nftToken][_nftTokenId] = NFTList({
        //         onSale: true,
        //         seller: msg.sender,
        //         token: _nftToken,
        //         tokenId: _nftTokenId
        // });

        //TODO Safe Transfer

        nft.transferFrom(_seller, address(this), _nftTokenId);

        emit OnSale(_nftTokenId, _nftToken, msg.sender);
    }

    function getOnSaleNFT(address _nftToken, uint256 _nftTokenId)
        public
        view
        returns (Nft memory)
    {
        return nftData[_nftToken][_nftTokenId];
    }

    function placeBid(
        address _nftToken,
        address _buyer,
        uint256 _price,
        uint256 _nftTokenId,
        address _paymentToken
    ) external payable isListedOnSaleNft(_nftToken, _nftTokenId) {
        //Checks:
        // -Seller cannot be buyer
        // -Token is on sale
        // -If current bid is higher than previous, replace the bid
        // -Time, Start time of auction should be less than current time (Auction Started or not)
        // -Time, End time of auction should be greater than current time (Auction Ended or not)
        // -Bidder has the amount to transfer or not?

        // Token nft = Token(_nftToken);
        IERC721 nft=IERC721(_nftToken);

        require(nft.ownerOf(_nftTokenId) != _buyer, "Seller cannot be buyer");
        require(
            _price >= nftData[_nftToken][_nftTokenId].heighestBid,
            "Bid less than highest bid price"
        );

        bidData[_nftToken][_nftTokenId] = Bid({
            buyer: _buyer,
            nftToken: _nftToken, //nft to be sold
            nftTokenId: _nftTokenId,
            price: _price,
            paidToken: _paymentToken
        });

        Nft storage listedNft = nftData[_nftToken][_nftTokenId];
        Bid storage bidList = bidData[_nftToken][_nftTokenId];

        // ZemToken payToken = ZemToken(biddersNFT.paidToken);
        IERC20 payToken = IERC20(bidList.paidToken);
        // console.log("Bidder Address: ", _buyer, "Balance of bidder: ", payToken.balanceOf(biddersNFT.buyer));

        payToken.approve(
            bidList.buyer,
            payToken.balanceOf(bidList.buyer)
        );

        payToken.transferFrom(bidList.buyer, address(this), _price);
        // console.log(payToken.balanceOf(_buyer));

        if (listedNft.lastBidder != address(0)) {
            address lastBidder = listedNft.lastBidder;
            uint256 lastBidPrice = listedNft.heighestBid;

            // Transfer back to last bidder
            payToken.approve(address(this), lastBidPrice);

            payToken.transferFrom(address(this), lastBidder, lastBidPrice);
            // console.log(payToken.balanceOf(address(this)));
        }

        // Set new heighest bid price
        listedNft.lastBidder = _buyer; //address buyer
        listedNft.heighestBid = _price;

        biddersData[_nftToken][_buyer] = true;
    }

    function getBid(address _nftToken, uint256 _nftTokenId)
        public
        view
        returns (Bid memory)
    {
        return bidData[_nftToken][_nftTokenId];
    }

    function updateBid(
        address _nftToken,
        address _buyer,
        uint256 _price,
        uint256 _nftTokenId
    ) external {
        //Checks:
        // -If buyer has already placed a bid?
        // -If update is not equal to the previous bid

        require(
            biddersData[_nftToken][_buyer],
            "Bid not placed by specified buyer"
        );

        Bid storage bidList = bidData[_nftToken][_nftTokenId];

        require(
            bidList.price != _price,
            "Updating Bid with same price is not allowed"
        );

        //TODO Interface can be used to call functions

        
        // ZemToken payToken = ZemToken(bidList.paidToken);
        IERC20 payToken = IERC20(bidList.paidToken);

        Nft storage nftonSale = nftData[_nftToken][_nftTokenId];

        payToken.approve(address(this), nftonSale.heighestBid);
        // IERC20.approve(address(this), nftonSale.heighestBid);

        payToken.transferFrom(address(this), _buyer, nftonSale.heighestBid);

        bidList.price = _price;
        nftonSale.heighestBid = _price;
        // console.log(nftonSale.heighestBid);

        payToken.transferFrom(_buyer, address(this), nftonSale.heighestBid);

        emit Updated(_nftTokenId, _nftToken, _buyer, _price);

    }

    function cancelBid(
        address _nftToken,
        address _buyer,
        uint256 _nftTokenId
    ) external {
        require(
            biddersData[_nftToken][_buyer],
            "Bid not placed by specified buyer"
        );

        Bid storage bidList = bidData[_nftToken][_nftTokenId];

        IERC20 payToken = IERC20(bidList.paidToken);
        // ZemToken payToken = ZemToken(bidList.paidToken);

        Nft storage nftList = nftData[_nftToken][_nftTokenId];

        // console.log(payToken.balanceOf(_buyer));
        // console.log(nftonSale.heighestBid);

        payToken.approve(address(this), nftList.heighestBid);
        payToken.transferFrom(address(this), _buyer, nftList.heighestBid);

        // console.log(payToken.balanceOf(_buyer));

        delete biddersData[_nftToken][_buyer];
        delete bidData[_nftToken][_nftTokenId];

        nftList.heighestBid = 0;
        nftList.lastBidder = address(0);

        emit Cancelled(_buyer, _nftToken, _nftTokenId);
    }

    function ConcludeAuction(address _nftToken, uint256 _nftTokenId) external {
        Nft storage auction = nftData[_nftToken][_nftTokenId];
        Bid storage bidList = bidData[_nftToken][_nftTokenId];

        // _NftsList[_nftToken][_nftTokenId] = NFTList({
        //         onSale: false,
        //         seller: msg.sender,
        //         token: _nftToken,
        //         tokenId: _nftTokenId
        // });


        IERC20 payToken = IERC20(bidList.paidToken);
        // ZemToken payToken = ZemToken(bidList.paidToken);
        IERC721 nft = IERC721(auction.token);
        // Token nft = Token(auction.token);
        auction.onSale = false;
        auction.sold = true;
        auction.winner = auction.lastBidder;
        uint256 totalPrice = auction.heighestBid;

        // console.log("Total Sale Price", totalPrice);

        // console.log("Balance before concluding: ", payToken.balanceOf(address(this)));
        // console.log("Creator: ", auction.royalityReceiver);
        // console.log("Seller: ", auction.seller);

        payToken.approve(address(this), auction.heighestBid);
        // console.log("Fee: ", auction.royalityFee);
        if (auction.royalityReceiver != auction.seller) {
            // console.log("Secondary Sale");
            uint256 creatorRoyalty = (totalPrice) / auction.royalityFee;
            // console.log(
            //     "Creator's Balance before: ",
            //     payToken.balanceOf(auction.royalityReceiver)
            // );
            // console.log(
            //     "Seller's  Balance before: ",
            //     payToken.balanceOf(auction.seller)
            // );
            // console.log("Creator Royality Fee", creatorRoyalty);
            payToken.transferFrom(
                address(this),
                auction.royalityReceiver,
                creatorRoyalty
            );
            // console.log(
            //     "Creator's Balance after concluding: ",
            //     payToken.balanceOf(auction.royalityReceiver)
            // );
            // console.log("Seller's profit: ", totalPrice - creatorRoyalty);

            payToken.transferFrom(
                address(this),
                auction.seller,
                totalPrice - creatorRoyalty
            );
            // console.log(
            //     "Seller's after concluding: ",
            //     payToken.balanceOf(auction.seller)
            // );
        } else {
            // console.log("First Sale");
            payToken.transferFrom(address(this), auction.seller, totalPrice);
        }
        // Transfer to auction creator
        // console.log("Balance after concluding: ", payToken.balanceOf(address(this)));

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);

        // console.log("New Owner: ", nft.ownerOf(_nftTokenId));
    }
}
