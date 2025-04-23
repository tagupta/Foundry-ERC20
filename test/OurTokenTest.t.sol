// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {OurToken} from "src/OurToken.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {IERC20Errors} from '@openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol';

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    uint256 public constant INITIAL_SUPPLY = 1000 ether;
    uint256 public constant STARTING_BALANCE = 100 ether;

    /**
     * @dev Script will deploy the OurToken contract
     * hence becoming the deployer of OurToken.
     * 
     */
    function setUp() external {
        deployer = new DeployOurToken();
        ourToken = deployer.run();
        vm.prank(msg.sender);
        ourToken.transfer(bob,STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                              BASIC TESTS
    //////////////////////////////////////////////////////////////*/

    function testInitialSupply() view external  {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testMetaData() view external {
        assertEq(ourToken.name(), ourToken.TOKEN_NAME());
        assertEq(ourToken.symbol(), ourToken.TOKEN_SYMBOL());
    }

    /*//////////////////////////////////////////////////////////////
                              TRANSFER TEST
    //////////////////////////////////////////////////////////////*/

    function test_BalanceOfBob() view  external {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function test_transferSuccess() external {
        //transfering tokens from bob to alice
        //Arrange
        uint transferAmount = 50 ether;
        //Act
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);
        //Assert
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);

    }

    function test_TransferInsufficientBalance() external {
        
        address from = bob;
        uint256 fromValue = ourToken.balanceOf(from);
        uint256 value = STARTING_BALANCE + 1;

        bytes memory expectedError = abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, from, fromValue, value);
        vm.expectRevert(expectedError);
        vm.prank(bob);
        ourToken.transfer(alice, STARTING_BALANCE + 1);
    }

    function test_tranferToZeroAddress() external {
        uint transferAmount = 50 ether;
        address receiver = address(0);
        bytes memory expectedError = abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, receiver);
        vm.prank(bob);
        vm.expectRevert(expectedError);
        ourToken.transfer(address(0), transferAmount);
    }
    /*//////////////////////////////////////////////////////////////
                             ALLOWANCE TEST
    //////////////////////////////////////////////////////////////*/
    function test_CheckAllowanceWorks() external {
        uint initialAllowanceBalance = 1000;
        //Bob approves Alice to spend tokens
        vm.prank(bob);
        ourToken.approve(alice, initialAllowanceBalance);
        uint256 tranferAmount = 500;
        vm.prank(alice);
        //Alice will going to tranfer the allowed tokens from bob to x
        ourToken.transferFrom(bob, alice, tranferAmount);
        uint aliceBalance = ourToken.balanceOf(alice);
        uint bobBalance = ourToken.balanceOf(bob);
        uint aliceLeftAllowncefromBob = ourToken.allowance(bob, alice);
        assertEq(aliceBalance, tranferAmount);
        assertEq(aliceLeftAllowncefromBob, initialAllowanceBalance - tranferAmount);
        assertEq(bobBalance, STARTING_BALANCE - tranferAmount);
    }
}
