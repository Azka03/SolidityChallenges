// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./IERC20.sol";

contract ZemToken is IERC20 {

    //Since solidity does not support decimal numbers so,  
    //Minting or transferring tokens may require number in decimals, (eg: 15.3Z)
    //ERC-20 uses 18 value for decimal
    //{token*10^(decimal)}  

    address public owner = msg.sender; //address that has called a function

    uint private _totalSupply = 1000000000000000000000000; //Tokens available - (1000000 + 18 0's)

    //address refers to the balance
    mapping (address => uint) private _balanceOf;

    //nested mapping, how much an address can spend used for approval function, (number of tokens that can be transferred)
    mapping (address => mapping (address => uint)) private _allowances;

    string public symbol  = "Z"; //symbol of our token //symbol of our token
    string public name = "Zem"; //name of our token
    uint8 decimals = 18;

    constructor(string memory _symbol,string memory _name,uint8 _decimal) public {
        _balanceOf[msg.sender] = _totalSupply; //balance of deploying adress = total tokens
        symbol  = _symbol; //symbol of our token //symbol of our token
        name = _name; //name of our token
        decimals = _decimal; 
    }

    //Returns total tokens 
    function totalSupply() public view returns (uint256) {
      return _totalSupply; 
    }

    //Returns balance of a given address
    function balanceOf(address _addr) public view returns (uint) {
        return _balanceOf[_addr];
    }

    //Returns a set amount of tokens from a spender to the owner
    function allowance(address _owner, address _spender) external view returns (uint) {
        return _allowances[_owner][_spender];
    }

    //Transfer amount of token from one account to another specified address
    function transfer(address _to, uint _value) public {
        
        //Amount of tokens to be transfered should be greater than 0 and less than total tokens in account
        require (_value > 0 && _value <= balanceOf(msg.sender), "Account does not have entered amount of tokens"); 
            _balanceOf[msg.sender] -= _value; //subtract amount of tokens transfered from sender
            _balanceOf[_to] += _value; //add amount of tokens transferred to receiver 
            emit Transfer(msg.sender, _to, _value); //emits event - stores data
    }

    //3rd party - Anyone can transfer amount from account to another account
    function transferFrom(address _from, address _to, uint _value) public override returns (bool) {
        
        require(_value <= _balanceOf[_from], "Account does not have entered amount of tokens"); 
        require(_value <= _allowances[msg.sender][_from], "Not approved to send this amount of tokens");   
        _balanceOf[_from] -= _value; //subtract amount of tokens transfered from sender
        _allowances[msg.sender][_from] -= _value; //subract amount of tokens allowed to spend
        _balanceOf[_to] += _value; //add amount of tokens transferred to receiver
        emit Transfer(_from, _to, _value); //emits event
        return true;
    }

    //Allow a spender to withdraw a set number of tokens from a specified account
    function approve(address _spender, uint _value) external override returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //Mints total supply to the given address, if some specific value is needed -> pass prameter for _value  
    function mint (address _to) external returns (bool) {
        require(msg.sender == owner);
        _balanceOf[_to] += _totalSupply; //_balanceOf[_to] += _value
        emit Transfer(address(0), _to, _totalSupply); 
        return true;
  }
}

