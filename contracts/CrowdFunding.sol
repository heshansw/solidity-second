// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public manager;

    uint public minContribution;
    uint public deadLine;
    uint public target;
    uint public raiseAmount;
    uint public noOfContributors;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool isCompleted;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) requests;
    uint public noOfRequests;

    modifier onlyManager() {
        require(msg.sender == manager, "Only Manager can call this function");
        _;
    }

    constructor(uint _target, uint _deadline) {
        target = _target;
        deadLine = block.timestamp + _deadline;
        minContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEther() public payable {
        require(block.timestamp < deadLine, "Deadline has passed");
        require(msg.value >= minContribution, "Minimum Contribution has not met");

        if(contributors[msg.sender] == 0) {
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raiseAmount += msg.value;
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function reFund() public {
        require(block.timestamp > deadLine, "Deadline has not expired yet!");
        require(raiseAmount < target, "Target has not met");
        require(contributors[msg.sender] > 0, "Should be a Contributor");

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager {
        Request storage newRequest = requests[noOfRequests];
        noOfRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.isCompleted = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "Not a contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    } 

    function makePayment(uint _requestNo) public onlyManager {
        require(raiseAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.isCompleted == false, "Already Distributed the amount");
        require(thisRequest.noOfVoters > noOfContributors/2, "Majority Support mark has not been crossed");

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.isCompleted = true;
    }

}