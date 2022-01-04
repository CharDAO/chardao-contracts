//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.7.0 <0.9.0;
contract donate{
    address public marketingAddress = 0x1aBACc90f9297BB221951CE9b12A7FE3F4762F37;
    address public devPayoutAddress = 0x43a8Ad77D5C56db80A627E37d14a5D4e4F59C87A; 
    
    //address public devPayoutAddress4 = 0x068797666966Bdac9354aF172b3604956cEce356; //J_Acc
    //address public devPayoutAddress5 = 0x30b15D2A67DcD2267748D182892bAe1489EEFDFb; //M_Acc

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
        uint yeildFarmMoney = (msg.value - (marketingMoney + devMoney));
        uint stagingMoney = (devMoney)/3;
        payable(marketingAddress).transfer(marketingMoney);
        payable(devPayoutAddress).transfer(devMoney);
        userIdNumber += 1;

        //creates the new donator
        Donator memory newDonator = Donator(msg.sender, yeildFarmMoney, block.timestamp, userIdNumber, block.timestamp, (yeildFarmMoney * 1 ether));
        donators[msg.sender] = newDonator;
        donatorsInGame.push(newDonator);
        payable(broker).transfer(yeildFarmMoney);
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

    function donationAfterCreation() payable public{
        require(msg.value >= .01 ether);
        require(msg.sender != broker, "broker cannot donate money");
        uint marketingMoney = (msg.value / 100) * 3;
        uint devMoney = (msg.value / 100) * 2;
        uint yeildFarmMoney = (msg.value - (marketingMoney + devMoney));
        payable(marketingAddress).transfer(marketingMoney);
        payable(devPayoutAddress).transfer(devMoney);
        //check this
        uint receiptTokens = yeildFarmMoney * 1 ether;
        if(payable(broker).send(yeildFarmMoney)){
            mintReceiptTokens(msg.sender, receiptTokens);
        }
        else{
            revert("The transaction failed");
        }
    }

    function yeildFarm() payable public{

    }

    function checkBalance(address donator) view public returns(uint) {
        return(balances[donator]);
    }


}
