//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "forge-std/Test.sol";
import "contracts/SampleERC20.sol";
import "./ICheatCodes.sol";

contract TestERC20 is SampleERC20, Test {
    CheatCodes cheat = CheatCodes(HEVM_ADDRESS);
    SampleERC20 ERC20;
    address addr1 = 0x393b996C9456Bc870ACb3dE3F987528C07D0580a;
    address addr2 = 0x458165AdAB6c343ea150C9D0Ae441040Eb3c502f;

    constructor(){
        ERC20 = new SampleERC20();
    }

    function setUp() public {
        ERC20.mint(addr1, 1e18);
        ERC20.mint(addr2, 1e18);
    }

    function testTransfer(uint256 value) public {
        if(value == 0) return;
        value = value % 1e18;
        if(ERC20.balanceOf(addr2) >= value) return;

        uint256 reciverBalance = ERC20.balanceOf(addr2);
        uint256 senderBalacne = ERC20.balanceOf(addr1);
        
        cheat.prank(addr1);
        ERC20.transfer(addr2, value);
        require(senderBalacne - ERC20.balanceOf(addr1) == value, "Balance didn't decrease");
        require(ERC20.balanceOf(addr2) - reciverBalance == value, "Balance didn't increase");
    }

    function testTransferFrom(uint256 value) public {
        if(value == 0) return;
        value = value % 1e18;
        if(ERC20.balanceOf(addr2) >= value) return;
        if(ERC20.allowance(addr1, addr2) < value) return;

        uint256 reciverBalance = ERC20.balanceOf(addr2);
        uint256 senderBalacne = ERC20.balanceOf(addr1);

        ERC20.transferFrom(addr2, addr1, value); // from to value
        require(senderBalacne - ERC20.balanceOf(addr1) == value, "Balance didn't decrease");
        require(ERC20.balanceOf(addr2) - reciverBalance == value, "Balance didn't increase");
    }

    function testApprove(uint256 value, uint256 amount) public {
        value = value % 1e18;
        if(value == 0) return;
        if(value < amount) return;
        if(ERC20.balanceOf(addr2) < amount) return;
        
        cheat.prank(addr1);
        ERC20.approve(addr2, value); // approve addr2 to spend addr1's balance
        require(ERC20.allowance(addr1, addr2) == value, "Allownace didn't change");

        emit log_uint(value);
        emit log_uint(amount);

        cheat.prank(addr2); // change msg.sender to addr2 (also, cheat.prank only lasts for 1 external call so we need to set prank everytime we call external non-view functions)
        //ERC20.transferFrom(addr2, addr1, amount);
        ERC20.transferFrom(addr1, addr2, amount);
        require(ERC20.allowance(addr1, addr2) == value - amount, "Allowance didn't decrease properly");
    }
}
