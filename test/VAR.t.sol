// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../src/Vintage&Rare.sol";
import "forge-std/Test.sol";

contract Test_NFT is Test {
    VintageAndRareNFTs nft;
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        vm.prank(owner);
        nft = new VintageAndRareNFTs(
            "Vintage and Rare: Acoustic Guitar",
            "V&R: Acoustic Guitars"
        );
        vm.deal(user1, 10 ether);
    }

    function test_mint_and_safekeep() public {
        uint balance = address(owner).balance;
        vm.prank(user1);
        vm.expectRevert();
        nft.mint("test");
        vm.prank(user1);
        nft.mint{value: 0.15 ether}("test");

        assertEq(address(owner).balance, balance + 0.15 ether);

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(address(user1)), 0);
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.tokenURI(1), "ipfs://test");
    }

    function test_mint_and_send() public {
        vm.prank(user1);
        nft.mint{value: 0.15 ether}("test");

        vm.prank(user2);
        vm.expectRevert();
        nft.claimMintedToken(1);

        vm.prank(user1);
        nft.claimMintedToken(1);
        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(address(nft)), 0);
        assertEq(nft.ownerOf(1), user1);
    }

    function test_transfer() public {
        vm.startPrank(user1);
        nft.mint{value: 0.15 ether}("test");

        nft.claimMintedToken(1);

        nft.transferFrom(user1, user2, 1);
        vm.stopPrank();

        assertEq(nft.balanceOf(user1), 0);
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.ownerOf(1), user2);
    }

    function test_contract_uri() public {
        assertEq(nft.contractURI(), "");
        vm.prank(owner);

        nft.setContractURI("ipfs://test");

        assertEq(nft.contractURI(), "ipfs://test");
    }
}
