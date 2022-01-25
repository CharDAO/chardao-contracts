//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Payment-Contract.sol";
contract HoldAvalanche {
    Donate donate;

    address thisContract;

    enum State {Deployed, Paying}
    State public state;

    constructor(address _paymentContract){
        thisContract = address(this);
        donate = Donate(_paymentContract);
        
    }

}