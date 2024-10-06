// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ballot {
    struct Voter {
        uint256 weight;
        bool hasVoted;
        address delegation;
        uint256 chosenProposal;
    }

    struct Proposal {
        bytes32 description;
        uint256 totalVotes;
    }

    address public electionAdmin;
    mapping(address => Voter) public registeredVoters;
    Proposal[] public proposalList;

    uint256 public votingStart;
    uint256 public votingEnd;

    constructor(bytes32[] memory proposalNames, uint256 votingDurationMinutes) {
        electionAdmin = msg.sender;
        registeredVoters[electionAdmin].weight = 1;

        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposalList.push(Proposal({description: proposalNames[i], totalVotes: 0}));
        }

        votingStart = block.timestamp;
        votingEnd = block.timestamp + (votingDurationMinutes * 1 minutes);
    }

    modifier onlyAdmin() {
        require(msg.sender == electionAdmin, "Only the admin can perform this action.");
        _;
    }

    modifier withinVotingPeriod() {
        require(block.timestamp >= votingStart, "Voting has not begun.");
        require(block.timestamp <= votingEnd, "Voting period is over.");
        _;
    }

    function authorizeVoter(address voter) external onlyAdmin {
        require(!registeredVoters[voter].hasVoted, "Voter has already voted.");
        require(registeredVoters[voter].weight == 0, "Voter is already authorized.");

        registeredVoters[voter].weight = 1;
    }

    function assignDelegate(address delegateAddress) external {
        Voter storage sender = registeredVoters[msg.sender];
        require(sender.weight > 0, "You are not authorized to vote.");
        require(!sender.hasVoted, "You have already cast your vote.");
        require(delegateAddress != msg.sender, "You cannot delegate to yourself.");

        while (registeredVoters[delegateAddress].delegation != address(0)) {
            delegateAddress = registeredVoters[delegateAddress].delegation;
            require(delegateAddress != msg.sender, "Delegation loop detected.");
        }

        Voter storage assignedDelegate = registeredVoters[delegateAddress];
        require(assignedDelegate.weight > 0, "Delegate is not authorized to vote.");
        
        sender.hasVoted = true;
        sender.delegation = delegateAddress;

        if (assignedDelegate.hasVoted) {
            proposalList[assignedDelegate.chosenProposal].totalVotes += sender.weight;
        } else {
            assignedDelegate.weight += sender.weight;
        }
    }

    function castVote(uint256 proposalIndex) external withinVotingPeriod {
        Voter storage sender = registeredVoters[msg.sender];
        require(sender.weight > 0, "You do not have voting rights.");
        require(!sender.hasVoted, "You have already cast your vote.");
        require(proposalIndex < proposalList.length, "Invalid proposal selected.");

        sender.hasVoted = true;
        sender.chosenProposal = proposalIndex;
        proposalList[proposalIndex].totalVotes += sender.weight;
    }

    function determineWinner() public view returns (uint256 leadingProposalIndex) {
        uint256 highestVotes = 0;
        for (uint256 i = 0; i < proposalList.length; i++) {
            if (proposalList[i].totalVotes > highestVotes) {
                highestVotes = proposalList[i].totalVotes;
                leadingProposalIndex = i;
            }
        }
    }

    function winnerDetails() external view returns (bytes32 winnerDescription) {
        winnerDescription = proposalList[determineWinner()].description;
    }
}
