//SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 <0.9.0;
contract Donate{
    //This is the payout structure

    /*
    address private marketingAddress = 0x1aBACc90f9297BB221951CE9b12A7FE3F4762F37;
    address private devPayoutAddress = 0x43a8Ad77D5C56db80A627E37d14a5D4e4F59C87A; 
    address private yeildFarmAddress = 0xeFD23625008f8255CeFe02c29d39b79db2a58372;
    */

    uint userIdNumber = 0;

    address public broker;

    mapping(address => Donator) donators; 
    mapping(address => uint) public balances;
    //the list of donators in the game
    Donator[] public donatorsInDao;
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
        donatorsInDao.push(newDonator);
        if(newDonator.receiptTokenAmt > 0){
            mintReceiptTokens(msg.sender, newDonator.receiptTokenAmt);
        }
        if(makeTransfer(payable(broker), msg.value)){
            return true;
        }else{
            return false;
        }
    }

//handles all transfers of crypto in the contract, uses call method, which is the recommended way to send coin
    function makeTransfer(address payable reciever, uint amount) private returns(bool){
        (bool sent,) = reciever.call{value: amount}("");
        require(sent, "Failed to send transaction");
        return sent;
    }

//mints receipt tokens based on the amount you donated
    function mintReceiptTokens (address receiver, uint amount) private minimumDonation{
        balances[receiver] += amount;
    }

//This allows users to donate again, after their initial donation
    function donationAfterCreation() payable public sansBroker minimumDonation{
        if(makeTransfer(payable(broker), msg.value)){
            donators[msg.sender].amountDonated = msg.value;
            donators[msg.sender].donateTime = block.timestamp;
            mintReceiptTokens(msg.sender, ((msg.value / 100) * 95));
        }
        else{
            revert("The transaction failed");
        }
    }

//allows people who danted, a way to see their receipt tokens
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
