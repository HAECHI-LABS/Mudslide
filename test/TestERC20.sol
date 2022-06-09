//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "forge-std/Test.sol";
import "contracts/SampleERC20.sol";
import "./ICheatCodes.sol";

contract TestERC20 is SampleERC20, Test {
    CheatCodes cheat = CheatCodes(HEVM_ADDRESS);
    SampleERC20 token;
    address addr1 = 0x393b996C9456Bc870ACb3dE3F987528C07D0580a;
    address addr2 = 0x458165AdAB6c343ea150C9D0Ae441040Eb3c502f;

    constructor(){
        token = new SampleERC20();
    }

    function setUp() public {
        token.mint(addr1, 1e18);
        token.mint(addr2, 1e18);
    }

    function testTransfer(uint256 value) public {
        cheat.assume(value <= token.balanceOf(addr1));

        uint256 receiverBalance = token.balanceOf(addr2);
        uint256 senderBalance = token.balanceOf(addr1);
        
        cheat.prank(addr1);
        token.transfer(addr2, value);

        assertEq(senderBalance - token.balanceOf(addr1), value);
        assertEq(token.balanceOf(addr2) - receiverBalance, value);
    }

    function testFailTransfer(uint256 value) public {
        cheat.assume(value > token.balanceOf(addr1));
        cheat.prank(addr1);
        token.transfer(addr2,value);
    }

    function testTransferFrom(uint256 allowance, uint256 transferAmount) public {
        cheat.assume(allowance >= transferAmount);
        cheat.assume(allowance < type(uint256).max); // to handle cases where erc20 contract assumes max allowance as infinite allowance
        cheat.assume(token.balanceOf(addr1) >= transferAmount);
        
        cheat.prank(addr1);
        token.approve(addr2, allowance); // approve addr2 to spend addr1's balance
        assertEq(token.allowance(addr1, addr2), allowance);

        cheat.prank(addr2); // change msg.sender to addr2 (also, cheat.prank only lasts for 1 external call so we need to set prank everytime we call external non-view functions)
        //token.transferFrom(addr2, addr1, amount);
        token.transferFrom(addr1, addr2, transferAmount);
        assertEq(token.allowance(addr1, addr2), allowance - transferAmount);
    }

    /// @dev tests if transferFrom fails when allowance is low
    function testFailTransferFromAllowance(uint256 allowance, uint256 transferAmount) public {
        cheat.assume(transferAmount <= token.balanceOf(addr1));
        cheat.assume(transferAmount > allowance);
        cheat.prank(addr1);
        token.approve(addr2, allowance);
        cheat.prank(addr2);
        token.transferFrom(addr1,addr2,transferAmount);
    }

    /// @dev tests if transferFrom fails when balance is low
    function testFailTransferFromBalance(uint256 allowance, uint256 transferAmount) public {
        cheat.assume(transferAmount > token.balanceOf(addr1));
        cheat.assume(transferAmount <= allowance);
        cheat.prank(addr1);
        token.approve(addr2, allowance);
        cheat.prank(addr2);
        token.transferFrom(addr1,addr2,transferAmount);
    }

    function testApprove(uint256 allowance) public {
        cheat.prank(addr1);
        token.approve(addr2, allowance);
        assertEq(token.allowance(addr1, addr2), allowance);
    }
}
