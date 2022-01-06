//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.7.0 <0.9.0;
contract donate{
    //This is the payout structure
    address private marketingAddress = 0x1aBACc90f9297BB221951CE9b12A7FE3F4762F37;
    address private devPayoutAddress = 0x43a8Ad77D5C56db80A627E37d14a5D4e4F59C87A; 
    address private yeildFarmAddress = 0xeFD23625008f8255CeFe02c29d39b79db2a58372;

    uint userIdNumber = 0;

    address public broker;

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

    modifier sansMinter{
        require(msg.sender != broker, "Broker Can't call this function");
        _;
    }

    modifier minimumDonation{
        require(msg.value >= .01 ether, "The minimum donation is .01 ether");
        _;
    }

    modifier onlyBroker{
        require(msg.sender == broker, "Only the broker can call this function");
        _;
    }

    function addADonator() payable public sansMinter minimumDonation{
        //this whole section sends the money to marketing and devs
        uint marketingMoney = (msg.value / 100) * 3;
        uint devMoney = (msg.value / 100) * 2;
        uint yeildFarmMoney = (msg.value - (marketingMoney + devMoney));
        payable(marketingAddress).transfer(marketingMoney);
        payable(devPayoutAddress).transfer(devMoney);
        userIdNumber += 1;

        //creates the new donator
        Donator memory newDonator = Donator(msg.sender, yeildFarmMoney, block.timestamp, userIdNumber, block.timestamp, (yeildFarmMoney * 1 ether));
        donators[msg.sender] = newDonator;
        donatorsInGame.push(newDonator);
        payable(broker).transfer(yeildFarmMoney);
        if(newDonator.receiptTokenAmt > 0){
            mintReceiptTokens(msg.sender, newDonator.receiptTokenAmt);
        }else{
            revert("No receipt tokens to mint at this time...donate money first");
        }
    }

    function mintReceiptTokens (address reciever, uint amount) private minimumDonation{
        Donator storage donator = donators[reciever];
        donator.donateTime = block.timestamp;
        //check this 
        amount = amount * 1 ether;
        balances[reciever] += amount;
    }

    function withdraw(uint amount, address reciever) payable public sansMinter{
        Donator storage donator = donators[reciever];
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

    function donationAfterCreation() payable public sansMinter{
        require(msg.value >= .01 ether);
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

    function yeildFarm(uint amount) payable public onlyBroker{
        //this is just going to be manual for now, need to talk to the community to see how to acheive this 
        payable(yeildFarmAddress).transfer(amount);
    }

    function checkBalance(address donator) view public returns(uint) {
        return(balances[donator]);
    }

    function voting() public sansMinter {
        
    }








}
