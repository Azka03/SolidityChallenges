// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./IERC721.sol";

import "hardhat/console.sol"; //console for debugging


contract Token is IERC721 {
 
    //Address refers to the balance (NFT count), Address will output count of NFTs
    mapping (address => uint) private _balanceOf;

    // nested mapping, is address approved to use NFTs, (owner to operator approvals)
    mapping (address => mapping (address => bool)) private _allowance;

    //NFTs mapped to owner addresses, tokenID will tell the owner
    mapping (uint => address) private _owners;

    //Map token ID to approved address, tokenID will tell approved address (address which can use the NFT)
    mapping (uint => address) private _approvedAddr;

    string public symbol = "Z"; //symbol of our NFT 
    string public name = "Zem"; //name of our NFT
    uint public tokenId = 0;

    constructor(string memory _symbol,string memory _name, uint _tokenId) public {
        symbol  = _symbol; //symbol of our token //symbol of our token
        name = _name; //name of our token
        tokenId = _tokenId; //Id of our token
    }

    //Returns balance of a given address (balance / no of NFTs in specified address)
    function balanceOf(address _addr) external view returns (uint) {
        return _balanceOf[_addr];
    }

    //Returns owner of the NFT specified by the token ID 
    function ownerOf(uint _tokenId) view public returns (address) {
      return _owners[_tokenId]; 
    }

    //Safely transfers the ownership of of specified Token ID
    //Checks:
    // If target address is a contract -> onERC721received should be implemented which returns certain value
    // msg.sender should be either owner or approvedowner
    function safeTransferFrom(address _from, address _to, uint _tokenId) public {
        //to be understood
    }

    //Transfers ownership of the specified token ID
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        //check if correct owner is trying to transfer
        require(ownerOf(_tokenId) == _from, "Transfer is only possible through owner.");

        //delete from mapping, tokenID no longer belongs to the previous address
        delete _approvedAddr[_tokenId];

        _balanceOf[_from] -= 1; //Substraction in NFT count of sender 
        _balanceOf[_to] += 1; //Addition in NFT count of receiver
        _owners[_tokenId] = _to; //Update the owner of the NFT

        emit Transfer(_from, _to, _tokenId); 
    }

    //approves using NFT
    function approve(address _to, uint _tokenId) public returns (bool) {
        address owner = ownerOf(_tokenId);
        require(owner == msg.sender || _allowance[owner][msg.sender], "Unable to approve, authority not granted");
        _approvedAddr[_tokenId] = _to;
        
        emit Approval(ownerOf(_tokenId), _to, _tokenId);

        return true;
    }

    //Returns approved address for specified token (who can transfer the token)   //useless?
    function getApproved(uint _tokenId) external view returns (address) {
        return _approvedAddr[_tokenId];
    }

    //Sets or updates approval 
    function setApprovedForAll(address _owner, address _operator, bool _approved) external{
        require(_owner!=_operator, "Self approval not allowed");
        _allowance[_owner][_operator]= _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    //Whether an operator is approved by the given owner
    function isApprovedForAll(address _owner, address _operator) external view returns (bool success){
        return _allowance[_owner][_operator];
    }

    function mint(address _to, uint _tokenId) external {
        _balanceOf[_to] += 1;
        _owners[_tokenId] = _to;

        //_tokenId++
        // console.log("TOKEN ID: ", _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }
}