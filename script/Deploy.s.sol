pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/stake.sol";
import "../src/vote.sol";
import "../src/nft.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        Stake stake = new Stake(address(0x0)); // адрес токена
        VoteResult nft = new VoteResult(deployerAddress);
        Voting voting = new Voting(address(stake), deployerAddress, address(nft));

        vm.stopBroadcast();

        console.log("Stake address is ", address(stake));
        console.log("VoteResult address is ", address(nft));
        console.log("Voting address is ", address(voting));
    }
}