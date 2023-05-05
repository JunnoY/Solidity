pragma solidity >=0.4.16 <0.7.0;

contract Paylock {

    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }

    int disc;
    State st;

    int clock;
    int collect_1_N_time;
    address timeAdd;

    constructor(address _timeAdd) public {
        st = State.Working;
        disc = 0;
        // initialise clock to be 0
        clock = 0;
        // collect_1_N time initialised
        collect_1_N_time = -1;
        // initialise timeAdd
        timeAdd = _timeAdd;
    }

    function signal() public {
        require( st == State.Working );
        st = State.Completed;
        disc = 10;
    }

    function collect_1_Y() public {
        // only succeed if called before the first deadline
        require( st == State.Completed, "Can only be called at Completed State");
        require(clock < 4, "Can only be called before the first deadline - Clock < 4");
        st = State.Done_1;
        disc = 10;
    }

    function collect_1_N() external {
        // only succeed if called after the first deadline has passed
        require( st == State.Completed, "Can only be called at Completed State");
        require(clock >= 4, "Can only be called when the first deadline has passed - Clock >= 4");
        st = State.Delay;
        disc = 5;
        collect_1_N_time = clock;
    }

    function collect_2_Y() external {
        // only succeed if called before the second deadline
        require( st == State.Delay, "Can only be called at the Delay state");
        require(clock < collect_1_N_time + 4, "Can only be called before 4 units after the time of collecting 1N");
        st = State.Done_2;
        disc = 5;
    }

    function collect_2_N() external {
        // only succeed if called after the second deadline has passed
        require( st == State.Delay, "Can only be called at the Delay state");
        require(clock >= collect_1_N_time + 4, "Can only be called when passing 4 units after the time of collecting 1N");
        st = State.Forfeit;
        disc = 0;
    }

    function tick() public {
        // can only be called by someone from the address timeAdd
        require(msg.sender == timeAdd, "Only someone from the valid address can call it.");
        clock += 1;
    }

}

contract Supplier {

    Paylock p;

    enum State { Working , Completed }

    State st;
    // Exercise 3
    // make sure acquire_resource() is called before return_resource() is called
    bool acquire_called;

    // Local variable representing an instance of the Rental contract
    Rental r;
    uint public deposit = 1 wei;

    receive() external payable {}

    constructor(address pp, address payable rr) public {
        p = Paylock(pp);
        st = State.Working;
        // initially acquire_resource is not acquire_called
        acquire_called = false;
        // rental instance
        r = Rental(rr);
    }

    function finish() external {
        require (st == State.Working);
        p.signal();
        st = State.Completed;
    }

    function acquire_resource() public payable{
        acquire_called = true;
        // call the appropriate functions in rental contract
        // send deposit to the rental contract
        (bool success, ) = address(r).call.value(deposit)(abi.encodeWithSignature("rent_out_resource()"));
        require(success, "Call failed");

    }

    function return_resource() public payable {
        require(acquire_called == true, "acquire_resource() is not called");
        // call the appropriate functions in rental contract
        r.retrieve_resource();
    }

    function getContractBalance() public view returns (uint256) {
    return address(this).balance;
}

}

contract Rental {

    address payable resource_owner;
    bool resource_available;
    uint public deposit = 1 wei;
    constructor() public {
        resource_available = true;
    }

    receive() external payable {}

    function rent_out_resource() external payable {
        require(resource_available == true);
        //CHECK FOR PAYMENT HERE
        //The supplier should give deposit of 1 wei to the resource owner, check if the message value is 1
        require(msg.value >= deposit, "Not enough deposit");
        resource_owner = msg.sender;
        resource_available = false;
    }

    function retrieve_resource() external payable {
        require(resource_available == false && msg.sender == resource_owner,"Condition does not meet");
        // RETURN DEPOSIT HERE
        (bool success, ) = address(resource_owner).call.value(deposit)("");
        require(success, "Call failed");
        resource_available = true;
    }
    function getContractBalance() public view returns (uint256) {
    return address(this).balance;
}
}