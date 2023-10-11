// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract HomebaseProject {
    // State variables
    address public author;
    address public client;
    address public contractor;
    address public arbiter;
    string public externalRequirementsDocLink;
    string public requirementsDocHash;
    uint256 public arbiterFee;
   
    enum ProjectStage {
        Open,
        Pending,
        Ongoing,
        Dispute,
        Expired,
        Closed
    }
    ProjectStage public stage;
   
    // Arrays and mappings
    address[] public acceptedTokens;
    mapping(address => mapping(uint256 => uint256)) public contributions;


    // Events
    event ProjectCreated(address indexed author, string requirementsDocHash);
    event ProjectUpdated(ProjectStage newStage);


    // Constructor Functions
    constructor(
        address _client,
        address _contractor,
        address _arbiter,
        string memory _externalRequirementsDocLink,
        string memory _requirementsDocHash
        ) {
        externalRequirementsDocLink = _externalRequirementsDocLink;
        requirementsDocHash = _requirementsDocHash;
       
        if (_client == address(0) || _contractor == address(0) || _arbiter == address(0)) {
            stage = ProjectStage.Open;
            author = msg.sender;
            client = msg.sender;
        } else {
            author = msg.sender;
            client = _client;
            contractor = _contractor;
            arbiter = _arbiter;
            stage = ProjectStage.Pending;
        }
        }


    function setParties(address _contractor, address _arbiter) public {
        require(stage == ProjectStage.Open, "Function can only be called in the Open stage");
        require(msg.sender == client, "Only the client can set the parties");
        contractor = _contractor;
        arbiter = _arbiter;
        stage = ProjectStage.Pending;
        emit ProjectUpdated(ProjectStage.Pending);
    }


    function signContract() public {
        require(stage == ProjectStage.Pending, "Function can only be called in the Pending stage");
        require(msg.sender == client || msg.sender == contractor, "Only the client or contractor can sign the contract");
        stage = ProjectStage.Ongoing;
        emit ProjectUpdated(ProjectStage.Ongoing);
    }


    function acceptPaymentTokens(address[] memory _tokens) public {
        require(msg.sender == contractor, "Only the contractor can set accepted tokens");
        acceptedTokens = _tokens;
    }




    // Funding Functions
    function sendFundsToProject(uint256 tokenIndex, uint256 amount) public {
        // TODO
    }


    function releaseFundsToContractor() public {
        // TODO
    }


    function withdrawSupport() public {
        // TODO
    }


    // Dispute Functions
    function initiateDispute() public {
        // TODO
    }


    function arbitrate(uint256 awardToContractor) public {
        // TODO
    }


    // Helper Functions
    // TODO


}


