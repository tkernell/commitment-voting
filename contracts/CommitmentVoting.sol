//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity 0.8.3;

contract Commitment2 is ERC20 {
    mapping(address => Locker) public lockers;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => Vote)) public votes;
    uint256 public proposalCount;
    uint256 public voteDuration;
    
    struct Proposal {
         address proposer;
         uint256 timestamp;
         uint256 votesFor;
         uint256 votesAgainst;
         bool executed;
         bool passed;
     }
    
    struct Locker {
         uint256 amount;
         uint256 unlockTimestamp;
    }
     
    struct Vote {
         bool voteFor;
         uint256 unlockTimestamp;
         uint256 amount;
         bool unlocked;
    }
    
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
     
    function proposeVote() public {
         Proposal storage proposal = proposals[proposalCount++];
         proposal.proposer = msg.sender; 
         proposal.timestamp = block.timestamp;
    }
     
    function submitVote(uint256 _proposalId, bool _inFavor, uint256 _duration, bool _addToLocker) public {
        require(proposalCount >= _proposalId, "Proposal id too high");
        require(balanceOf(msg.sender) > 0, "Token balance is zero");
        Locker storage locker = lockers[msg.sender];
        if(locker.unlockTimestamp < block.timestamp) {
            locker.unlockTimestamp = block.timestamp;
        }
        if(_addToLocker && balanceOf(msg.sender) > locker.amount) {
            if(locker.amount > 0 && locker.unlockTimestamp > block.timestamp) {
                locker.unlockTimestamp = locker.unlockTimestamp * locker.amount / balanceOf(msg.sender);
            }
            locker.amount = balanceOf(msg.sender);
        }
        
        if(_inFavor) {
            proposals[_proposalId].votesFor += locker.amount * _duration;
        } else {
            proposals[_proposalId].votesAgainst += locker.amount * _duration;
        }
        locker.unlockTimestamp += _duration;
    }
    
    function executeVote(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposalCount >= _proposalId, "Proposal id too high");
        require(block.timestamp > proposal.timestamp + voteDuration, "Vote period not expired");
        require(!proposal.executed, "Proposal already executed");
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
        }
        proposal.executed = true;
    }
    
    function unlock(uint256 _amount) public {
        Locker storage locker = lockers[msg.sender];
        require(locker.unlockTimestamp <= block.timestamp, "Unlock timestamp not expired");
        require(locker.amount >= _amount, "Insufficient balance in locker");
        locker.amount -= _amount;
    }
    
    function undoLosingResolutions(uint256 _proposalId) public {
        Vote storage vote = votes[msg.sender][_proposalId];
        Locker storage locker = lockers[msg.sender];
        require(vote.unlocked);
        require(vote.amount > 0);
        if (vote.unlockTimestamp > block.timestamp && locker.unlockTimestamp > block.timestamp) {
            
        }
        vote.unlocked = true;
    }
    
    // function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
    //      require(balanceOf(from) - lockers[from].amount >= amount || from == address(0), "Insufficient unlocked balance");
    //  }
}