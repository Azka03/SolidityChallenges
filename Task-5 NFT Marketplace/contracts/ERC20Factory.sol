// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./zem.sol"; //import contract
import "./IERC20.sol"; //import interface -> use functions through this 

import "hardhat/console.sol"; //console for debugging


contract ERC20Factory{

    //Stores address of tokens been deployed - contract type is taken because when we deploy, we are creating object of ZemToken contract 
    ZemToken[] public _ZemTokens;

    //Addresses refer whether it is whitelisted or not by owner -> msg.sender
    mapping (address => bool) public _onlyWhiteListed;
  
    //Takes name, symbol and decimals as parameters and it mints initial supply to the deployed token
    function deployToken(string memory _symbol, string memory _name, uint8 deci, uint _value) public {

        //Creates instance of our contract and send symbol, name and decimals as parameters
        ZemToken zemtoken = new ZemToken( _symbol, _name, deci);

        //Populating the array, here if array type was address then error would have occured due to different types
        _ZemTokens.push(zemtoken);  

        // console.log("Bal before minting " , zemtoken.balanceOf(msg.sender));

        //Calling mint function through our instance and minting the total supply
        zemtoken.mint(_value);

        // console.log("Bal after minting ", zemtoken.balanceOf(msg.sender));
    }

    //Returns addresses of deployed tokens
    function tokenAddresses() public view returns (ZemToken[] memory) {
        return _ZemTokens;
    }

    // Maps address to boolean value.. (True => isWhiteListed)
    function setWhiteListed(address addr, bool flag) public {
        require(!_onlyWhiteListed[addr], "This state already exists"); //Mapping will return true/false (true!=false - go ahead)
       _onlyWhiteListed[addr] = flag; //Add/update the state of address provided
    }

    //Returns state of the address
    function getWhiteListed(address addr) public view returns (bool) {
         return _onlyWhiteListed[addr]; //mapping to bool will return true or false
    }

    //Modifier executes before execution of the function
    modifier onlyWhiteListed(address addr){
        require(_onlyWhiteListed[addr], "Address not whiteListed"); //checks whether address is whitelister or not
        _; //executes before function
    }

    //Uses modifier to withdraw tokens to another address
    function withdrawTokens(address token_addr, address addr1, uint _value) public onlyWhiteListed(msg.sender) {
        require(_value<=100000, "Withdraw of maximum 100000 tokens is allowed per transaction");
        
        IERC20(token_addr).transfer(addr1, _value);
        // console.log(IERC20(token_addr).balanceOf(addr1));
    }

    //takes user wallet as input and return all deployed tokens via factory balances.
    function balanceOfAll ( address wallet_addr) public view returns (address[] memory,uint[] memory) {    

        //storing length of array in local variable as calling state variable again and again will increase the cost 
        uint Zemtokenslen=_ZemTokens.length;

        //local array to store addresses
        address[] memory addArr = new address[] (Zemtokenslen);

        //local array to store balances of address
        uint[] memory balArr = new uint[] (Zemtokenslen);
            
        //Loop to iterate through all addresses and balances
        for(uint i=0; i<Zemtokenslen; i++){
            
            //Populating addresses of deployed tokens in local array
            addArr[i] = address(_ZemTokens[i]);  
        
            //Populating balances of users wallets in local array 
            balArr[i]=IERC20(_ZemTokens[i]).balanceOf(wallet_addr);   
        }

        return (addArr, balArr);
    }   
}

