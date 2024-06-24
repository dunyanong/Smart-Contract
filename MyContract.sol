// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract CryptoKids {
    // The owner of the contract, referred to as "Dad"
    address owner;

    // fires when kids receive money
    event LogKidFundingReceived(address addr, uint amount, uint contractBalance);

    // Constructor to set the owner of the contract to the address that deploys it
    constructor() {
        owner = msg.sender;
    }

    // Define a struct to hold information about each kid
    struct Kid {
        address payable walletAddress;
        string firstName;
        string lastName;
        uint releaseTime; // Time when the kid is allowed to withdraw
        uint balance; // Amount of funds allocated to the kid
        bool canWithdraw; // Flag to check if the kid is allowed to withdraw
    }

    // Array to store all kids
    Kid[] public kids;

    // so that u don't have to repeat the statement: "require(msg.sender == owner, "Only sender can add kids");"    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only sender can add kids");
        _;
    }

    // Function to add a kid to the contract, only callable by the owner
    function addKid(
        address payable walletAddress,
        string memory firstName,
        string memory lastName,
        uint releaseTime,
        uint balance,
        bool canWithdraw
    )
        public
        onlyOwner
    {
        kids.push(Kid(
            walletAddress,
            firstName,
            lastName,
            releaseTime,
            balance,
            canWithdraw
        ));
    }

    // Function to get the balance of the contract
    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    // Function to deposit funds to the contract for a specific kid's account
    function depositFunds(address walletAddress) public payable {
        updateKidBalance(walletAddress);
    }

    // Internal function to update the balance of a specific kid
    function updateKidBalance(address walletAddress) private onlyOwner {
        for (uint i = 0; i < kids.length; i++) {
            if (kids[i].walletAddress == walletAddress) {
                kids[i].balance += msg.value;
                emit LogKidFundingReceived(walletAddress, msg.value, getContractBalance());
            }
        }
    }

    function getIndex(address walletAddress) view private returns(uint) {
        for (uint i = 0; i < kids.length; i++) {
            if (kids[i].walletAddress == walletAddress) {
                return i;
            }
        }
        return 999;
    }

    // check if the kid is able to widthdraw
    function availableToWidthdraw(address walletAddress) public returns(bool) {
        uint i = getIndex(walletAddress);
        require(block.timestamp > kids[i].releaseTime, "You cannot withdraw yet");
        if (block.timestamp > kids[i].releaseTime) {
            kids[i].canWithdraw = true;
            return true;
        } else {
            return false;
        }
    }

    // withdraw money 
    function withdraw(address walletAddress) payable public {
        uint i = getIndex(walletAddress);
        require(msg.sender == kids[i].walletAddress, "You must be the kid to withdraw");
        require(kids[i].canWithdraw == true, "You are not able to withdraw at this time");
        kids[i].walletAddress.transfer(kids[i].balance);
    }
}