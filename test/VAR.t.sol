// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../src/Vintage&Rare.sol";
import "forge-std/Test.sol";

contract Test_NFT is Test {
    VintageAndRare nft;

    function setUp() public {
        nft = new VintageAndRare();
    }

    function test_mint_and_send() public;

    function test_mint_and_safekeep() public;

    function test_transfer() public;
}
