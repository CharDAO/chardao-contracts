//SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 <0.9.0;
contract Donate{
    //This is the payout structure

    uint userIdNumber = 0;
    address public broker;

    mapping(address => Donator) donators; 
    mapping(address => uint) public balances;
    mapping(address => uint) public identityNumber;

    //the list of donators in the game
    Donator[] public donatorsInDao;

    //the donator with this various attributes
    struct Donator{
        address donatorAddress;
        uint amountDonated;
        uint donatorCreationTime;
        uint ID;
        uint donateTime;
        uint receiptTokenAmt;
    }

    //sets deyployment address as contract broker
    constructor() payable{
        broker = msg.sender;
    }

    //MODIFIERS 
    modifier sansBroker{
        require(msg.sender != broker, "Broker Can't call this function");
        _;
    }

    modifier doNotDuplicate{
        bool inPool = true;
        if(identityNumber[msg.sender] > 0){
            inPool = false;
        }
        require(inPool, "Address has already donated");
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
    function addADonator() payable public sansBroker minimumDonation doNotDuplicate returns(bool){
        userIdNumber += 1;
        identityNumber[msg.sender] = userIdNumber;
        //creates the new donator
        Donator memory newDonator = Donator(msg.sender, msg.value, block.timestamp, userIdNumber, block.timestamp, msg.value);
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
        donatorsInDao[(identityNumber[receiver] - 1)].donateTime += block.timestamp;
        balances[receiver] += amount;
    }

//This allows users to donate again, after their initial donation
    function donationAfterCreation() payable public sansBroker minimumDonation{
        if(makeTransfer(payable(broker), msg.value)){
            donators[msg.sender].amountDonated = msg.value;
            donators[msg.sender].donateTime = block.timestamp;
            donatorsInDao[(identityNumber[msg.sender] - 1)].amountDonated += msg.value;
            donatorsInDao[(identityNumber[msg.sender] - 1)].receiptTokenAmt += msg.value;
            mintReceiptTokens(msg.sender, msg.value);
        }
        else{
            revert("The transaction failed");
        }
    }

//allows people who donated, a way to see their receipt tokens
    function checkBalance(address donator) view public returns(uint) {
        return(balances[donator]);
    }

//Function returns data to the ballot contract
    function checkIfDonated(address _donator) view public returns(bool hasDonated){
        if(balances[_donator] > 0){
            return true;
        }else{
            return false;
        }
    }
//Function returns data to the ballot contract 
    function checkDonationAmount(address _donator) view public returns(uint amountDonated){
        return balances[_donator];
    }

    function getReceiptTokenAmt(address _donator) view public returns(uint){
        return donators[_donator].receiptTokenAmt;
    }

}
