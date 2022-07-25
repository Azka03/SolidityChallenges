// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IERC721 {

    function balanceOf(address _owner) external view returns (uint balance);

    function ownerOf(uint _tokenId) external view returns (address tokenOwner);

    function safeTransferFrom(address _from, address _to, uint _tokenId) external;

    function transferFrom(address _from, address _to, uint _tokenId) external;

    function approve(address _to, uint _tokenId) external returns (bool success);

    function getApproved(uint _tokenId) external returns (address _owner);

    function setApprovedForAll(address owner, address operator, bool _approved) external;

    function isApprovedForAll(address _owner, address operator) external returns (bool success);

    function mint(address _to,uint _tokenId) external;

    // function transfer(address _from, address _to, uint _tokenId) external;

    event Transfer(address indexed _from, address indexed _to, uint _tokenId);
    event Approval(address indexed _owner, address indexed _spender, uint _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _spender, bool approved);
}