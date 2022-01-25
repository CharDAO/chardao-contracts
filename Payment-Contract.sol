//SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 <0.9.0;
contract Donate{
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
    address[] public addressToPay;


    //the donator with this various attributes
    struct Donator{
        address donatorAddress;
        uint amountDonated;
        uint donatorCreationTime;
        uint ID;
        uint donateTime;
        uint receiptTokenAmt;
        uint amtToWithdraw;
        //bool hasDonated;
    }

    //sets us as the boker
    constructor() payable{
        broker = msg.sender;
    }

    //MODIFIERS 
    modifier sansBroker{
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

    //FUNCTION 
    function addADonator() payable public sansBroker minimumDonation returns(bool){
        uint marketingMoney = (msg.value / 100) * 3;
        uint devMoney = (msg.value / 100) * 2;
        uint yeildFarmMoney = (msg.value - (marketingMoney + devMoney));
        userIdNumber += 1;

        //creates the new donator
        Donator memory newDonator = Donator(msg.sender, yeildFarmMoney, block.timestamp, userIdNumber, block.timestamp, (yeildFarmMoney), 0);
        donators[msg.sender] = newDonator;
        donatorsInGame.push(newDonator);
        if(newDonator.receiptTokenAmt > 0){
            mintReceiptTokens(msg.sender, newDonator.receiptTokenAmt);
        }else{
            revert("No receipt tokens to mint at this time...donate money first");
        }

//Does this add Protection form payment faliure?
        if(makeTransfer(payable(marketingAddress), marketingMoney) && makeTransfer(payable(devPayoutAddress), devMoney) &&makeTransfer(payable(broker), yeildFarmMoney)){
            return true;
        }else{
            return false;
        }
    }

    function makeTransfer(address payable reciever, uint amount) private returns(bool){
        (bool sent,) = reciever.call{value: amount}("");
        require(sent, "Failed to send transaction");
        if(sent){
            return true;
        }else{
            return false;
        }
    }

    function mintReceiptTokens (address receiver, uint amount) private minimumDonation{
        //Donator storage donator = donators[receiver];
        donators[receiver].donateTime = block.timestamp;
        balances[receiver] += amount;
    }


    function withdraw(uint amount, address reciever) payable public sansBroker{
        Donator storage donator = donators[reciever];
       //require(block.timestamp >= donators[msg.sender].donateTime + (15552000)*2); //time lock 
        require(amount <= donator.receiptTokenAmt);
        balances[reciever] -= amount;

        donator.amtToWithdraw = amount;
        addressToPay.push(reciever);

    }

    function brokerWithdraw() payable public onlyBroker{
        for(uint i = 0; i < addressToPay.length; i++){ 
            uint amount = donators[addressToPay[i]].amtToWithdraw;
            donators[addressToPay[i]].amtToWithdraw = 0;
            (bool sent, ) = addressToPay[i].call{value: amount}("");
            require(sent, "Failed to send transaction");
        }
        //clears the array
        delete addressToPay;
    }

    function getData(address _receiver) view public returns(uint){
        uint withdrawalAMT = donators[_receiver].amtToWithdraw;
        return(withdrawalAMT);
    }

    function donationAfterCreation() payable public sansBroker{
        require(msg.value >= .01 ether);
        uint marketingMoney = (msg.value / 100) * 3;
        uint devMoney = (msg.value / 100) * 2;
        uint yeildFarmMoney = (msg.value - (marketingMoney + devMoney));
        //payable(marketingAddress).transfer(marketingMoney);
        //payable(devPayoutAddress).transfer(devMoney);
        //check this
        uint receiptTokens = yeildFarmMoney * 1 ether;
        if(makeTransfer(payable(marketingAddress), marketingMoney) && makeTransfer(payable(broker), yeildFarmMoney) && makeTransfer(payable(devPayoutAddress), devMoney)){
            mintReceiptTokens(msg.sender, receiptTokens);
        }
        else{
            revert("The transaction failed");
        }
    }

    function checkBalance(address donator) view public returns(uint) {
        return(balances[donator]);
    }
//Function returns data to the ballot contract
    function checkIfDonated(address receiver) view public returns(bool hasDonated){

        if(balances[receiver] > 0){
            return true;
        }else{
            return false;
        }
    }
//Function returns data to the ballot contract 
    function checkDonationAmount(address receiver) view public returns(uint amountDonated){
        return balances[receiver];
    }

}
