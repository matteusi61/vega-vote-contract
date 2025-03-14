pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/stake.sol";
import "../src/vote.sol";
import "../src/nft.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address erc20 = vm.envAddress("ERC20_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        Stake stake = new Stake(erc20);
        VoteResult nft = new VoteResult(deployerAddress);
        Voting voting = new Voting(address(stake), deployerAddress, address(nft));

        vm.stopBroadcast();

        console.log("Stake address is ", address(stake));
        console.log("VoteResult address is ", address(nft));
        console.log("Voting address is ", address(voting));
    }
}
