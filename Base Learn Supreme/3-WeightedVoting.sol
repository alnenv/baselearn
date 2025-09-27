// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.6/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.6/contracts/utils/structs/EnumerableSet.sol";

contract WeightedVoting is ERC20 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Errors
    error TokensClaimed();
    error AllTokensClaimed();
    error NoTokensHeld();
    error QuorumTooHigh(uint proposed);
    error AlreadyVoted();
    error VotingClosed();

    // Spec
    uint public constant maxSupply = 1_000_000;
    uint private constant CLAIM_AMOUNT = 100;
    mapping(address => bool) public hasClaimed;

    enum Vote { AGAINST, FOR, ABSTAIN }

    // Urutan persis sesuai soal
    struct Issue {
        EnumerableSet.AddressSet voters; // 1
        string issueDesc;                // 2
        uint votesFor;                   // 3
        uint votesAgainst;               // 4
        uint votesAbstain;               // 5
        uint totalVotes;                 // 6
        uint quorum;                     // 7
        bool passed;                     // 8
        bool closed;                     // 9
    }

    Issue[] private issues;

    struct IssueView {
        address[] voters;
        string issueDesc;
        uint votesFor;
        uint votesAgainst;
        uint votesAbstain;
        uint totalVotes;
        uint quorum;
        bool passed;
        bool closed;
    }

    constructor() ERC20("Weighted Voting Token", "WVT") {
        // burn zeroeth element
        issues.push();
        Issue storage p = issues[0];
        p.closed = true;
        p.issueDesc = "burned-zero-index";
    }

    // v4.9: decimals() adalah view; set ke 0 agar angka tes cocok
    function decimals() public view override returns (uint8) {
        return 0;
    }

    // Claim 100 token sekali per wallet, hingga cap
    function claim() public {
        if (hasClaimed[msg.sender]) revert TokensClaimed();
        if (totalSupply() + CLAIM_AMOUNT > maxSupply) revert AllTokensClaimed();
        hasClaimed[msg.sender] = true;
        _mint(msg.sender, CLAIM_AMOUNT);
    }

    // Hanya holder; urutan cek: NoTokensHeld -> QuorumTooHigh
    function createIssue(string calldata _desc, uint _quorum) external returns (uint) {
        if (balanceOf(msg.sender) == 0) revert NoTokensHeld();
        if (_quorum > totalSupply()) revert QuorumTooHigh(_quorum);

        issues.push();
        uint id = issues.length - 1;
        Issue storage isx = issues[id];
        isx.issueDesc = _desc;
        isx.quorum = _quorum;
        return id;
    }

    function getIssue(uint _id) external view returns (IssueView memory) {
        Issue storage isx = issues[_id];
        return IssueView({
            voters: isx.voters.values(),
            issueDesc: isx.issueDesc,
            votesFor: isx.votesFor,
            votesAgainst: isx.votesAgainst,
            votesAbstain: isx.votesAbstain,
            totalVotes: isx.totalVotes,
            quorum: isx.quorum,
            passed: isx.passed,
            closed: isx.closed
        });
    }

    function issuesLength() external view returns (uint) {
        return issues.length;
    }

    function vote(uint _issueId, Vote _vote) public {
        Issue storage isx = issues[_issueId];
        if (isx.closed) revert VotingClosed();

        uint weight = balanceOf(msg.sender);
        if (weight == 0) revert NoTokensHeld();
        if (isx.voters.contains(msg.sender)) revert AlreadyVoted();
        isx.voters.add(msg.sender);

        if (_vote == Vote.FOR) {
            isx.votesFor += weight;
        } else if (_vote == Vote.AGAINST) {
            isx.votesAgainst += weight;
        } else {
            isx.votesAbstain += weight;
        }
        isx.totalVotes += weight;

        if (isx.totalVotes >= isx.quorum) {
            isx.closed = true;
            if (isx.votesFor > isx.votesAgainst) isx.passed = true;
        }
    }
}
