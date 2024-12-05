// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FootballBets
 * @dev A contract that allows users to place bets on football matches, submit match results, 
 * and distribute payouts to winners based on their bets.
 */
contract FootballBets {
    // Owner of the contract (responsible for managing matches and submitting results)
    address public owner;

    // Struct to represent a football match and its associated data
    struct Match {
        uint matchId; // Unique ID of the match
        string teamA; // Name of Team A
        string teamB; // Name of Team B
        bool isOpen; // Indicates if betting is open for this match
        string winningTeam; // Name of the winning team (or "draw" if applicable)
        uint256 totalBetsTeamA; // Total amount of bets placed on Team A
        uint256 totalBetsTeamB; // Total amount of bets placed on Team B
        mapping(address => uint256) betsTeamA; // Mapping of bettors and their bets on Team A
        mapping(address => uint256) betsTeamB; // Mapping of bettors and their bets on Team B
    }

    // Mapping of match IDs to their corresponding Match struct
    mapping(uint => Match) public matches;
    // ID of the currently active match
    uint public currentMatch;

    // Arrays to keep track of bettors for Team A and Team B
    address[] public bettersTeamA;
    address[] public bettersTeamB;

    // Modifier to restrict function execution to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    // Modifier to check if a match exists
    modifier matchExists(uint matchId) {
        require(matches[matchId].matchId == matchId, "Match does not exist.");
        _;
    }

    // Modifier to ensure betting is still open for the match
    modifier isOpen(uint matchId) {
        require(matches[matchId].isOpen, "Betting is closed for this match.");
        _;
    }

    /**
     * @dev Constructor to initialize the contract with the owner's address.
     * @param _owner Address of the contract owner.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Creates a new football match. Only one match can be open at a time.
     * @param matchId Unique ID for the match.
     * @param teamA Name of Team A.
     * @param teamB Name of Team B.
     */
    function createMatch(uint256 matchId, string memory teamA, string memory teamB) public {
        require(matches[matchId].matchId != matchId, "Match already exists.");
        require(matches[currentMatch].isOpen == false, "Another match is still ongoing.");
        
        Match storage newMatch = matches[matchId];
        newMatch.matchId = matchId;
        newMatch.teamA = teamA;
        newMatch.teamB = teamB;
        newMatch.isOpen = true;
        currentMatch = matchId;
    }

    /**
     * @dev Allows a user to place a bet on a team for the current match.
     * @param team Name of the team the user wants to bet on.
     * @return bool True if the bet was successfully placed, false otherwise.
     */
    function placeBet(string memory team) public payable matchExists(currentMatch) isOpen(currentMatch) returns (bool) {
        require(msg.value > 0, "Bet amount must be greater than zero.");
        Match storage matchData = matches[currentMatch];

        uint256 before = bettersTeamA.length + bettersTeamB.length;

        if (keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked(matchData.teamA))) {
            matchData.betsTeamA[msg.sender] += msg.value;
            matchData.totalBetsTeamA += msg.value;
            bettersTeamA.push(msg.sender);
        } else if (keccak256(abi.encodePacked(team)) == keccak256(abi.encodePacked(matchData.teamB))) {
            matchData.betsTeamB[msg.sender] += msg.value;
            matchData.totalBetsTeamB += msg.value;
            bettersTeamB.push(msg.sender);
        } else {
            revert("Invalid team selected for the bet.");
        }

        uint256 test = bettersTeamA.length + bettersTeamB.length;

        return before + 1 == test;
    }

    /**
     * @dev Submits the result of a match and closes betting for it.
     * @param winningTeam Name of the winning team or "draw" if the match ended in a tie.
     */
    function submitResult(string memory winningTeam) public {
        Match storage matchData = matches[currentMatch];
        require(matchData.isOpen, "Results already submitted.");
        require(
            keccak256(abi.encodePacked(winningTeam)) == keccak256(abi.encodePacked(matchData.teamA)) ||
            keccak256(abi.encodePacked(winningTeam)) == keccak256(abi.encodePacked(matchData.teamB)) ||
            keccak256(abi.encodePacked(winningTeam)) == keccak256(abi.encodePacked("draw")),
            "Invalid winning team."
        );

        matchData.isOpen = false;
        matchData.winningTeam = winningTeam;

        payoutWinners(currentMatch);
    }

    /**
     * @dev Distributes payouts to winners based on their bets for a specific match.
     * @param matchId ID of the match for which payouts are to be made.
     */
    function payoutWinners(uint matchId) public matchExists(matchId) {
        require(matches[matchId].isOpen == false, "Match is still open.");
        Match storage matchData = matches[matchId];
        uint256 totalBets = matchData.totalBetsTeamA + matchData.totalBetsTeamB;

        if (keccak256(abi.encodePacked(matchData.winningTeam)) == keccak256(abi.encodePacked(matchData.teamA))) {
            for (uint i = 0; i < bettersTeamA.length; i++) {
                address betterAddr = bettersTeamA[i];
                uint256 percentage = (matchData.betsTeamA[betterAddr] * 1000) / matchData.totalBetsTeamA;
                uint256 outputValue = (percentage * totalBets) / 1000;
                payable(betterAddr).transfer(outputValue);
            }
        } else if (keccak256(abi.encodePacked(matchData.winningTeam)) == keccak256(abi.encodePacked(matchData.teamB))) {
            for (uint i = 0; i < bettersTeamB.length; i++) {
                address betterAddr = bettersTeamB[i];
                uint256 percentage = (matchData.betsTeamB[betterAddr] * 1000) / matchData.totalBetsTeamB;
                uint256 outputValue = (percentage * totalBets) / 1000;
                payable(betterAddr).transfer(outputValue);
            }
        }
    }

    /**
     * @dev Allows anyone to view the total bets placed on both teams for a specific match.
     * @param matchId ID of the match.
     * @return uint256 Total bets on Team A and Team B.
     */
    function viewSetBets(uint matchId) public view matchExists(matchId) returns (uint256, uint256) {
        Match storage matchData = matches[matchId];
        return (matchData.totalBetsTeamA, matchData.totalBetsTeamB);
    }
}
