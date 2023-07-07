// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ManualToken {

    mapping (address => uint256) private s_balances;

    string public name = "Manual Token";

    constructor() {
        
    }

    function totalSupply() public pure returns (uint256){
        return 100 ether;
    }

    function decimals() public pure returns(uint8){
        return 18;
    }
    function balanceOf(address _owner) public view returns (uint256){
        return s_balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public{
        address _from = msg.sender;
        uint256 prevBalance = balanceOf(_from) + balanceOf(_to);
        s_balances[_from] -= _amount;
        s_balances[_to] += _amount;
        require(balanceOf(_from) + balanceOf(_to) == prevBalance);
    }
}