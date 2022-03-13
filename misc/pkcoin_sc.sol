pragma solidity 0.6.6;

contract PKCoin {
    int balance;

    constructor() public {
        balance = 0;
    }

    function getBalance() view public returns(int) {
        return balance;
    }

    function depositBalance(int amount) public {
        balance = balance + amount;
    }

    function withdrawlBalance(int amount) public {
        balance = balance - amount;
    }
}