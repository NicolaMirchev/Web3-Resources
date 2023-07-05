// SPDX-License-Identifier: MIT
pragma solidity 0.8.18; 

contract SimpleStorage {
    uint256 public myFavouriteNumber;

    Person[] public persons;
    mapping (string => uint256) public favouriteNumbers;

    struct Person{
        uint256 favouriteNumber;
        string name;
    }

    function store(uint _favNumber) public virtual {
        myFavouriteNumber = _favNumber;
    }

    function addNumber(uint256 number, string memory name) public {
        persons.push(Person(number, name));
        favouriteNumbers[name] = number;
    }


    function retrieve() public view returns(uint256){
        return myFavouriteNumber;
    }
}