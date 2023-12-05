// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";

contract Deploy_NFT is Script {
    function run() public {
        console.log("Deploy Vintage And Rare NFT");

        vm.startBroadcast();
        vm.stopBroadcast();
    }
}
