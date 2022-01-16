//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Payment-Contract.sol";

contract ballot{

    Donate donate;

    //VARIABLES
    struct vote{
        address voterAddress;
        uint choice;
    }

    struct voter{
        uint amountDonated;
        bool voted;
        bool proposed;
        bool added;
    }

    uint private countResult = 0;
    uint public finalResult = 0;
    uint public totalVoter = 0;
    uint public totalVote = 0;
    uint private propCount = 0;
    uint[5] public voteRegister = [0,0,0,0,0];
    

    address public ballotBroker;
    address private otherContract;
    address[] public voterAddressRegister;
    string public ballotOfficialName;
    string[] public proposals;

    mapping(uint => vote) private votes;
    mapping(address => voter) public voterRegister;

    enum State {Created, Interum, Proposal, Voting, End }
    State public state;


    //MODIFIERS
    modifier condition(bool _condition){
        require(_condition);
        _;
    }

    modifier onlyOfficial(){
        require(msg.sender == ballotBroker, "Only the broker can call this contract");
        _;
    }

    modifier inState(State _state){
        require(state == _state, "Not in correct State");
        _;
    }

    modifier didDonate(){
        bool testVar = donate.checkIfDonated(msg.sender);
        require(testVar, "You need to donate first!");
        _;
    }

    modifier moreThanFive(){
        require(voterAddressRegister.length > 5, "Too few registered voters");
        _;
    }

    //EVENTS 

    //FUNCTIONS
    constructor(address _otherContract){
            ballotBroker = msg.sender;
            state = State.End;
            otherContract = _otherContract;
            donate = Donate(_otherContract);
    }

    function newBallot(string memory _ballotOfficialName) public inState(State.End) onlyOfficial{
        ballotOfficialName = _ballotOfficialName;
        state = State.Created; 
    }

    function registerToVote() public inState(State.Created) didDonate{
        voter memory v;
        v.amountDonated = donate.checkDonationAmount(msg.sender);
        v.voted = false;
        v.proposed = false;
        v.added = true;
        voterRegister[msg.sender] = v;
        voterAddressRegister.push(msg.sender);
        totalVoter++;
    }

    function startProposal() public onlyOfficial moreThanFive{
        state = State.Proposal;
    }

    function addProposal(string memory _proposal) public inState(State.Proposal) didDonate{
        if(!voterRegister[msg.sender].proposed && voterRegister[msg.sender].added){
            if(proposals.length < 5){
                voterRegister[msg.sender].proposed = true;
                proposals.push(_proposal);
            }
            if(proposals.length == 5){
                state = State.Interum;
            }
        }

    }

    function checkProp()view public returns(uint){
        return(proposals.length);
    }

    function startVote() public inState(State.Interum) onlyOfficial{
        state = State.Voting;
    }

    function doVote(uint _choice) public inState(State.Voting) didDonate returns(bool voted){
        bool found = false;

        //fix
        if(!voterRegister[msg.sender].voted){
            vote memory v;
            v.voterAddress = msg.sender;
            v.choice = _choice;
            if(_choice == 1){
                voteRegister[0] += 1;
                voterRegister[msg.sender].voted = true;
            }
            else if(_choice == 2){
                voteRegister[1] += 1;
                voterRegister[msg.sender].voted = true;
            }
            else if(_choice == 3){
                voteRegister[2] += 1;
                voterRegister[msg.sender].voted = true;
            }
            else if(_choice == 4){
                voteRegister[3] += 1;
                voterRegister[msg.sender].voted = true;
            }
            else if(_choice == 5){
                voteRegister[4] += 1;
                voterRegister[msg.sender].voted = true;
            }
            else{
                revert("That was not a valid choice");
            }
            votes[totalVote] = v;
            totalVote++;
            found = true;
        }
        return found;
    }

    function endVote() public onlyOfficial inState(State.Voting) returns(uint){
        state = State.End;
        uint winIndex = 0;
        uint greatestVotes = 0;
        turnBackTime();
        for(uint i = 0; i < 5; i++){
            if(voteRegister[i] > greatestVotes){
                greatestVotes = voteRegister[i];
                winIndex = i;
            }
        }
        finalResult = winIndex;
        return finalResult;
    }
    function turnBackTime() private{
        for( uint i = 0; i < voterAddressRegister.length; i++) {
            voterRegister[voterAddressRegister[i]].voted = false;
            voterRegister[voterAddressRegister[i]].proposed = false;
            voterRegister[voterAddressRegister[i]].added = false;
        }
    }
}