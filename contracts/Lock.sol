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
        // For storing Ether contributions
    mapping(address => uint256) public etherContributions;

    // For ERC20 Tokens
    function contributeTokens(uint256 tokenIndex, uint256 amount) public {
        address tokenAddress = acceptedTokens[tokenIndex];
        IERC20 token = IERC20(tokenAddress);
        
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        contributions[msg.sender][tokenIndex] += amount;
    }

    // For Ether
    receive() external payable {
        etherContributions[msg.sender] += msg.value;
    }

   function releaseFundsToContractor() public {
        require(stage == ProjectStage.Ongoing, "Funds can only be released in the Ongoing stage");
        require(msg.sender == client, "Only the client can release funds");

        // Release Ether
        uint256 etherAmount = etherContributions[client];
        if (etherAmount > 0) {
            payable(contractor).transfer(etherAmount);
            etherContributions[client] = 0;
        }

        // Release Tokens
        for (uint i = 0; i < acceptedTokens.length; i++) {
            address tokenAddress = acceptedTokens[i];
            uint256 tokenAmount = contributions[client][i];
            
            if (tokenAmount > 0) {
                IERC20 token = IERC20(tokenAddress);
                require(token.transfer(contractor, tokenAmount), "Token transfer failed");
                contributions[client][i] = 0;
            }
        }

        stage = ProjectStage.Closed;
        emit ProjectUpdated(ProjectStage.Closed);
    }


// Allow contributors to withdraw their funds
// Allow contributors to withdraw their funds
    function withdrawSupport() public {
        require(
            stage == ProjectStage.Pending || 
            stage == ProjectStage.Dispute || // Assuming arbiter ruled for withdrawal
            // Add any other condition set by the contractor here
            false, 
            "Withdrawals are not allowed in the current stage"
        );

        // Withdraw Ether
        uint256 etherAmount = etherContributions[msg.sender];
        if (etherAmount > 0) {
            payable(msg.sender).transfer(etherAmount);
            etherContributions[msg.sender] = 0;
        }

        // Withdraw Tokens
        for (uint i = 0; i < acceptedTokens.length; i++) {
            uint256 tokenAmount = contributions[msg.sender][i];
            if (tokenAmount > 0) {
                IERC20 token = IERC20(acceptedTokens[i]);
                require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
                contributions[msg.sender][i] = 0;
            }
        }
    }


    // Initiate a dispute
    function initiateDispute() public {
        require(stage == ProjectStage.Ongoing, "Disputes can only be initiated in the Ongoing stage");
        require(msg.sender == client || msg.sender == contractor, "Only the client or contractor can initiate a dispute");

        stage = ProjectStage.Dispute;
        emit ProjectUpdated(ProjectStage.Dispute);
    }

    // Arbitrate a dispute
    function arbitrate(uint256 awardToContractor) public {
        require(stage == ProjectStage.Dispute, "Arbitration can only occur in the Dispute stage");
        require(msg.sender == arbiter, "Only the arbiter can arbitrate");

        // Award to contractor (This is simplified; you'd likely want more complex logic)
        if (awardToContractor > 0) {
            payable(contractor).transfer(awardToContractor);
        }

        stage = ProjectStage.Closed;
        emit ProjectUpdated(ProjectStage.Closed);
    }


}