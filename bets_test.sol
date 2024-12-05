// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../TermProject/bets.sol";

contract testSuite {

    FootballBets footballBets;

    address acc0;
    address acc1;
    address acc2;

    uint256 acc2BalanceBefore;

    /// #sender: account-0
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);   

        footballBets = new FootballBets(acc0);
        footballBets.createMatch(1, "A", "B");

        Assert.equal(msg.sender, acc0, "Error: ");
        Assert.equal(footballBets.owner(), acc0, "Error: ");
    }

    /// #sender: account-0
    function testCreateMatch() public {
        uint256 actualId = footballBets.currentMatch();
        uint256 expectedId = 1;
        Assert.equal(actualId, expectedId, "Wrong match ID found");
    }

    /// #value: 100000000
    /// #sender: account-1
    function placeFirstBet() public payable{
        footballBets.placeBet{value: 100000000}("A");
        (uint256 totalBetsTeamA, uint256 totalBetsTeamB) = footballBets.viewSetBets(1);
        Assert.equal(totalBetsTeamA, 100000000, "Wrong bet amount set");
    }

    /// #value: 100
    /// #sender: account-2
    function placeSecondBet() public payable{     
        footballBets.placeBet{value: 100}("B");
        (uint256 totalBetsTeamA, uint256 totalBetsTeamB) = footballBets.viewSetBets(1);
        Assert.equal(totalBetsTeamB, 100, "Wrong bet amount set");
    }

    function testViewSetBets() public {     
        (uint256 betsTeamA, uint256 betsTeamB) = footballBets.viewSetBets(1);
        Assert.equal(betsTeamA, 100000000, "Wrong amount found");
        Assert.equal(betsTeamB, 100, "Wrong amount found");
    }
}
