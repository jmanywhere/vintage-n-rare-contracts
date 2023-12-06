// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import {VintageAndRareNFTs} from "../src/Vintage&Rare.sol";

contract Deploy_NFT is Script {
    function run() public {
        vm.startBroadcast();
        VintageAndRareNFTs nft = new VintageAndRareNFTs(
            "Vintage & Rare: Acoustic Guitar",
            "V&R: Acoustic Guitar"
        );
        console.log("Acoustic Guitar: %s", address(nft));
        nft = new VintageAndRareNFTs(
            "Vintage & Rare: Amps & Effects",
            "V&R: Amps & Effects"
        );
        console.log("Amps & Effects: %s", address(nft));
        nft = new VintageAndRareNFTs(
            "Vintage & Rare: Electric Bass",
            "V&R: Electric Bass"
        );
        console.log("Electric Bass: %s", address(nft));
        nft = new VintageAndRareNFTs(
            "Vintage & Rare: Electric Guitar",
            "V&R: Electric Guitar"
        );
        console.log("Electric Guitar: %s", address(nft));

        vm.stopBroadcast();
    }
}
