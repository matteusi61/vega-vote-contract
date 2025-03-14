pragma solidity ^0.8.26;

import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {VoteResult} from "src/nft.sol";
import {Stake} from "src/stake.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Voting is AccessControl, IERC721Receiver, Ownable {
    struct Vote {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 threshold;
        uint256 yesCount;
        uint256 noCount;
        bool isOver;
        address[] participants;
        uint256 sumPower;
    }

    bytes32 public constant ADMIN = keccak256("ADMINCHIK");
    Stake public staking;
    VoteResult public nft;
    Vote[] public votes;
    uint256 public nextVoteId;

    event VoteCreated(uint256 id, string description);
    event VoteEnded(uint256 id, bool result);
    event VoteResultsInfo(uint256 voteId, address participant, VoteResult.Result info);

    struct ReceivedNFT {
        address contractAddress;
        uint256 tokenId;
    }

    ReceivedNFT[] public receivedNFTs;

    constructor(address _staking, address _admin, address _nft) Ownable(msg.sender) {
        _grantRole(ADMIN, _admin);
        staking = Stake(_staking);
        nft = VoteResult(_nft);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        receivedNFTs.push(ReceivedNFT({contractAddress: msg.sender, tokenId: tokenId}));

        return this.onERC721Received.selector;
    }

    function _stackPower() internal view returns (uint256) {
        uint256 total = 0;
        uint256 keysLength = staking.getKeysLength();
        if (keysLength == 0) {
            return total;
        }
        for (uint256 i = 0; i < keysLength; i++) {
            address keyAddr = staking.getKeysAddr(i);
            require(keyAddr != address(0), "Invalid key address");
            uint256 votingPower = staking.calculateVotingPower(keyAddr);
            total += votingPower;
        }
        return total;
    }

    function createVote(string memory description, uint256 duration, uint256 threshold) external onlyRole(ADMIN) {
        address[] memory participants = new address[](0);
        votes.push(
            Vote({
                id: nextVoteId,
                description: description,
                deadline: block.timestamp + duration,
                threshold: threshold,
                yesCount: 0,
                noCount: 0,
                isOver: false,
                participants: participants,
                sumPower: _stackPower()
            })
        );
        emit VoteCreated(nextVoteId, description);
        nextVoteId++;
    }

    function vote(uint256 voteId, bool choice) external {
        Vote storage s = votes[voteId];
        s.participants.push(msg.sender);
        require(!s.isOver, "Vote ended");
        require(block.timestamp <= s.deadline, "Too late deadline is passed");

        uint256 power = staking.calculateVotingPower(msg.sender);
        require(power > 0, "No voting power");

        if (choice) {
            s.yesCount += power;
        } else {
            s.noCount += power;
        }
    }

    function finalVotes() external onlyRole(ADMIN) {
        for (uint256 i = 0; i < votes.length; i++) {
            Vote storage s = votes[i];
            if (s.yesCount + s.noCount >= s.threshold * s.sumPower / 100 || block.timestamp > s.deadline) {
                s.isOver = true;
                VoteResult.Result memory info;
                info.id = s.id;
                info.yesCount = s.yesCount;
                info.noCount = s.noCount;
                info.result = s.yesCount > s.noCount;

                nft.mint(owner(), info);
                emit VoteEnded(i, s.yesCount > s.noCount);

                for (uint256 j = 0; j < s.participants.length; j++) {
                    emit VoteResultsInfo(i, s.participants[j], info);
                }
            }
        }
    }
}
