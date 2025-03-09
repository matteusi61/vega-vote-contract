pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {VegaVoteToken} from "../src/token.sol";
import {Stake} from "../src/stake.sol";
import {Voting} from "../src/vote.sol";
import {VoteResult} from "../src/nft.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract VotingTest is Test, IERC721Receiver {

    VegaVoteToken token;
    Stake stake;
    VoteResult nft;
    Voting voting;
    
    address owner; 
    address admin = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    address user666 = address(0x666);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setUp() public {
        owner = address(this); 
        token = new VegaVoteToken();
        stake = new Stake(address(token));
        nft = new VoteResult(address(this)); 
        voting = new Voting(address(stake), admin, address(nft));

        token.transfer(user1, 1000 ether);
        token.transfer(user2, 1000 ether);
        token.transfer(user666, 6000 ether);

        vm.startPrank(user1);
        token.approve(address(stake), 1000 ether);
        stake.stake(1000 ether, 365 days);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(stake), 1000 ether);
        stake.stake(1000 ether, 365 days);
        vm.stopPrank();

        vm.startPrank(user666);
        token.approve(address(stake), 1000 ether);
        stake.stake(1000 ether, 365 days);
        vm.stopPrank();
    }

    function testCreateSession() public {
        vm.prank(admin);
        voting.createVote("Test Vote 1", 1 days, 90);
 
        (uint256 id, string memory desc,, uint256 threshold,,,,) = voting.votes(0);
        assertEq(id, 0);
        assertEq(threshold, 90);
        assertEq(keccak256(bytes(desc)), keccak256(bytes("Test Vote 1")));

        vm.prank(user1);
        vm.expectRevert();
        voting.createVote("Test Vote 2", 1 days, 30);

        vm.prank(user2);
        vm.expectRevert();
        voting.createVote("Test Vote 3", 1 days, 70);        

    }

    function testVote() public {
        vm.prank(admin);
        voting.createVote("Test Vote 1", 1 days, 90);

        vm.prank(user1);
        voting.vote(0, true);

        vm.prank(user2);
        voting.vote(0, false);

        vm.prank(user666);
        voting.vote(0, true);

        (,,,, uint256 yesCount, uint256 noCount,,) = voting.votes(0);
        assertGt(yesCount, 0);
        assertGt(noCount, 0);
    }

    function testAutoFinalization() public {
        vm.prank(admin);
        voting.createVote("Test Vote", 1 days, 90); 
        vm.prank(user1);
        voting.vote(0, true);
        vm.prank(user2);
        voting.vote(0, false);
        vm.prank(user666);
        voting.vote(0, true);

        vm.prank(user1);
        vm.expectRevert();
        voting.finalVotes();

        vm.prank(user666);
        vm.expectRevert();
        voting.finalVotes();

        vm.prank(admin);
        voting.finalVotes();
        (,,,,,,bool isFinalized,) = voting.votes(0);
        assertTrue(isFinalized);
    }

    function testGetTokenBack() public {
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), 0);
        assertEq(token.balanceOf(user666), 5000 ether);

        vm.warp(block.timestamp + 5 days);

        vm.startPrank(user666);
        token.approve(address(stake), 5000 ether);
        stake.stake(5000 ether, 666 days);
        vm.stopPrank();
        assertEq(token.balanceOf(user666), 0 ether); 

        vm.warp(block.timestamp + 400 days);

        vm.prank(user1);
        stake.getTokenBack();
        vm.prank(user2);
        stake.getTokenBack();
        vm.prank(user666);
        stake.getTokenBack();

        assertEq(token.balanceOf(user1), 1000 ether);
        assertEq(token.balanceOf(user2), 1000 ether);
        assertEq(token.balanceOf(user666), 1000 ether);

        vm.warp(block.timestamp + 800 days);
        vm.prank(user666);
        stake.getTokenBack();
        assertEq(token.balanceOf(user666), 6000 ether);
    }
}