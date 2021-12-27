//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.7.0 <0.9.0;
contract donate{
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
        idCheck += 1;
        Donator memory newDonator = Donator(msg.sender, msg.value, block.timestamp, idCheck, 0, 0);
        donators[msg.sender] = newDonator;
        donatorsInGame.push(newDonator);
  
    }

    function mintReceiptTokens (address reciever, uint amount) payable public {
        Donator storage donator = donators[reciever];
        require(msg.sender == broker, "Only the contract creator can mint");
        require(donator.amountDonated > 0);
        donator.donateTime = block.timestamp;
        //get the donator to send the donation
        //trigger the receipt token minting when a donators sends eth 
        balances[reciever] += amount;

    }

    function withdraw(uint amount) payable public{
         //this is the 6 month time lock
        address reciever = msg.sender;
        Donator storage donator = donators[reciever];
        require(block.timestamp >= donators[msg.sender].donateTime + 15552000 );
        require(amount <= donator.receiptTokenAmt);
        balances[reciever] -= amount;
    }

    function checkBalance(address donator) view public returns(uint) {
        return(balances[donator]);
    }


}
