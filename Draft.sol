//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.7.0 <0.9.0;
contract donate{
    address public marketingAddress = 0xBB6B5C07C038cba58148d82722629117c5EfE2c9;
    address public devPayoutAddress = 0xBB6B5C07C038cba58148d82722629117c5EfE2c9;
    address public brokerV2Address = 0xBB6B5C07C038cba58148d82722629117c5EfE2c9;

    //each donator gets their own id 
    uint userIdNumber = 0;

    //we are the broker, but we automate this task
    address public broker;

    //maps the donator to a variable and the balances of the donators
    mapping(address => Donator) donators; 
    mapping(address => uint) public balances;

    //the list of donators in the game
    Donator[] public donatorsInGame;

    //the donator with this various attributes
    struct Donator{
        address donatorAddress;
        uint amountDonated;
        uint donatorCreationTime;
        uint ID;
        uint donateTime;
        uint receiptTokenAmt;
    }

    //sets us as the boker
    constructor() payable{
        broker = msg.sender;
    }

    function addADonator() payable public{
        require(msg.sender != broker, "broker cannot donate");
        require(msg.value >= .01 ether, "The minumum donation is .01 ether");

        //this whole section sends the money to marketing and devs
        uint marketingMoney = (msg.value / 100) * 3;
        uint devMoney = (msg.value / 100) * 2;
        uint actualDonationMoney = msg.value - (marketingMoney + devMoney);
        payable(marketingAddress).transfer(marketingMoney);
        payable(devPayoutAddress).transfer(devMoney);
        userIdNumber += 1;
        //creates the new donator
        Donator memory newDonator = Donator(msg.sender, actualDonationMoney, block.timestamp, userIdNumber, block.timestamp, (actualDonationMoney * 1 ether));
        donators[msg.sender] = newDonator;
        donatorsInGame.push(newDonator);
        payable(broker).transfer(msg.value);
        mintReceiptTokens(msg.sender, newDonator.receiptTokenAmt);
    }

    function mintReceiptTokens (address reciever, uint amount) private {
        Donator storage donator = donators[reciever];
        require(donator.amountDonated > .01 ether);
        donator.donateTime = block.timestamp;

        //check this 
        amount = amount * 1 ether;

        balances[reciever] += amount;
    }

    function withdraw(uint amount, address reciever) payable public{
        Donator storage donator = donators[reciever];
        require(msg.sender != broker, "The broker cannot withdraw funds");
        require(block.timestamp >= donators[msg.sender].donateTime + (15552000)*2); //time lock 
        require(amount <= donator.receiptTokenAmt);
        uint etherAmount = amount * (1 ether);
        if(payable(msg.sender).send(etherAmount)){
            balances[reciever] -= amount;

        /* 
        how do we get the line above to send from teh broker address?
        As of now it sends tokens from the person who requested the withdrawl.
        I don't know how to specify the sender address other than the person sending the request.

        Work on this part please !!
        */

        }
        else{
            revert("The transaction failed");
        }
    }

    function donationAfterCreation(uint amount) payable public{
        require(amount >= .01 ether);
        require(msg.sender != broker, "broker cannot donate money");
        //check this
        uint receiptTokens = amount * 1 ether;
        if(payable(broker).send(amount)){
            mintReceiptTokens(msg.sender, receiptTokens);
        }
        else{
            revert("The transaction failed");
        }
    }

    function checkBalance(address donator) view public returns(uint) {
        return(balances[donator]);
    }


}
