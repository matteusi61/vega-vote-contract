    pragma solidity ^0.8.26;

    import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
    import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

    contract Stake is ReentrancyGuard {

        struct Stak {
            uint256 amount;
            uint256 startTime;
            uint256 period; 
        }

        uint256 public constant secInDay = 24 * 60 * 60;
        ERC20 public token;
        mapping(address => Stak[]) public stakes;
        address[] public keys;

        constructor(address _token) {
            token = ERC20(_token);
        }

        function stake(uint256 amount, uint256 period) external nonReentrant {
            require(period / secInDay / 365 <= 4, "period must be less than 4 years");
            token.transferFrom(msg.sender, address(this), amount);
            stakes[msg.sender].push(Stak(amount, block.timestamp, period));
            keys.push(msg.sender);
        }

        function calculateVotingPower(address user) public view returns (uint256) {
            uint256 votePower;
            for (uint256 i = 0; i < stakes[user].length; i++) {
                Stak memory x = stakes[user][i];
                if (block.timestamp < x.startTime + x.period) {
                    votePower += x.amount * ((x.period - uint256((block.timestamp - x.startTime) / secInDay )) ** 2);
                }
            }
            return votePower;
        }

        function getTokenBack() external nonReentrant {
            Stak[] storage userStakes = stakes[msg.sender];
            uint256 i = 0;
            while (i < userStakes.length) {
                Stak memory x = userStakes[i];
                if (block.timestamp >= x.startTime + x.period) {
                    token.transfer(msg.sender, x.amount);
                    userStakes[i] = userStakes[userStakes.length - 1];
                    userStakes.pop();
                } else {
                    i++;
                }
            }
        }

        function getKeysLength() external view returns (uint256) {
            return keys.length;
        }

        function getKeysAddr(uint256 index) external view returns (address) {
            return keys[index];
        }
    }