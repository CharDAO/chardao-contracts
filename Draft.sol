//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.7.0 <0.9.0;
contract donate{
    address public marketingAddress = 0xBB6B5C07C038cba58148d82722629117c5EfE2c9;
    address public devPayoutAddress = 0xBB6B5C07C038cba58148d82722629117c5EfE2c9;
    address public brokerV2Address = 0xBB6B5C07C038cba58148d82722629117c5EfE2c9;

    //each donator gets their own id 
    uint idCheck = 0;

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

        //dont know why these lines are throwing error
        uint marketingMoney = (msg.value / 100) * 3;
        uint devMoney = (msg.value / 100) * 2;
        uint actualDonationMoney = msg.value - (marketingMoney + devMoney);
        payable(marketingAddress).transfer(marketingMoney);
        payable(devPayoutAddress).transfer(devMoney);
        idCheck += 1;
        Donator memory newDonator = Donator(msg.sender, actualDonationMoney, block.timestamp, idCheck, 0, 0);
        donators[msg.sender] = newDonator;
        donatorsInGame.push(newDonator);
        payable(broker).transfer(msg.value);
        mintReceiptTokens(msg.sender, actualDonationMoney);
    }

    function mintReceiptTokens (address reciever, uint amount) private {
        Donator storage donator = donators[reciever];
        require(donator.amountDonated > .01 ether);
        donator.donateTime = block.timestamp;
        //get the donator to send the donation
        //trigger the receipt token minting when a donators sends eth 
        balances[reciever] += amount;

    }

    function withdraw(uint amount, address reciever) payable public{
        Donator storage donator = donators[reciever];
         //this is the 6 month time lock
        require(msg.sender != broker, "The broker cannot withdraw funds");
        require(block.timestamp >= donators[msg.sender].donateTime + (15552000)*2);
        require(amount <= donator.receiptTokenAmt);
        //this basically just burns the tokens
        balances[reciever] -= amount;
        uint etherAmount = amount * (1 ether);
        payable(msg.sender).transfer(etherAmount); 
        /* 
        how do we get the line above to send from teh broker address?
        As of now it sends tokens from the person who requested the withdrawl.
        I don't know how to specify the sender address other than the person sending the request.

        Work on this part please !!
        */


    }

    function checkBalance(address donator) view public returns(uint) {
        return(balances[donator]);
    }


}
