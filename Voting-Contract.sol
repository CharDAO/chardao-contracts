//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.0 <0.9.0;
contract ballot{

    //VARIABLES
    struct vote{
        address voterAddress;
        bool choice;
    }

    struct voter{
        uint amountDonated;
        bool voted;
    }

    uint private countResult = 0;
    uint public finalResult = 0;
    uint public totalVoter = 0;
    uint public totalVote = 0;
    uint private propCount = 0;
    uint[5] public voteRegister = [0,0,0,0,0];
    

    address public ballotBroker;
    string public ballotOfficialName;
    string[5] public proposals;

    mapping(uint => vote) private votes;
    mapping(address => voter) public voterRegister;

    enum State {Created, Interum, Proposal, Voting, Ended }
    State public state;


    //MODIFIERS
    modifier condition(bool _condition){
        require(_condition);
        _;
    }

    modifier onlyOfficial(){
        require(msg.sender == ballotBroker);
        _;
    }

    modifier inState(State _state){
        require(state == _state);
        _;
    }

    modifier didDonate(){
        require(donators[msg.sender].amountDonated >= .01 ether);
        _;
    }

    //EVENTS 

    //FUNCTIONS
    constructor(
        string memory _ballotOfficialName
        ){
            ballotBroker = msg.sender;
            ballotOfficialName = _ballotOfficialName;
            state = State.Created; 
    }

    function addVoter(address _voterAddress) public inState(State.Created) didDonate{
        voter memory v;
        v.voted = false;
        voterRegister[_voterAddress] = v;
        totalVoter++;
    }

    function startProposal() public onlyOfficial{
        state = State.Proposal;
    }

    function addProposal(string _proposal) public inState(State.Proposal){
        if(proposals.length < 5){
            proposals[propCount] = _proposal;
        }
        if(proposals.length == 5){
            state = State.Interum;
        }
    }

    function startVote() public inState(State.Interum) onlyOfficial{
        state = State.Voting;
    }

    function doVote(uint _choice) public inState(State.Voting) returns(uint voted){
        bool found = false;
        if(bytes(voterRegister[msg.sender].voterName).length != 0 && !voterRegister[msg.sender].voted){
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

    function endVote() public onlyOfficial inState(State.Voting) returns(uint voteWinner){
        state = State.Ended;
        uint winIndex = 0;
        for(int i = 0; i <= 5; i++){
            if(voteRegister[i-1] > winIndex){
                winIndex = voterRegister[i-1];
            }
        }
        finalResult = winIndex;
        return(finalResult);
    }
}