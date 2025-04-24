// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {OurToken} from "src/OurToken.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {IERC20Errors} from "@openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Vm} from "forge-std/Vm.sol";
import {CommonBase} from 'forge-std/Base.sol';

contract MockContract {

}
contract OurTokenTest is CommonBase, Test {
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
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                              BASIC TESTS
    //////////////////////////////////////////////////////////////*/

    function testInitialSupply() external view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testMetaData() external view {
        assertEq(ourToken.name(), ourToken.TOKEN_NAME());
        assertEq(ourToken.symbol(), ourToken.TOKEN_SYMBOL());
    }

    /*//////////////////////////////////////////////////////////////
                              TRANSFER TEST
    //////////////////////////////////////////////////////////////*/

    function test_BalanceOfBob() external view {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function test_transferSuccess() external {
        //transfering tokens from bob to alice
        //Arrange
        uint256 transferAmount = 50 ether;
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

        bytes memory expectedError =
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, from, fromValue, value);
        vm.expectRevert(expectedError);
        vm.prank(bob);
        ourToken.transfer(alice, STARTING_BALANCE + 1);
    }

    function test_tranferToZeroAddress() external {
        uint256 transferAmount = 50 ether;
        address receiver = address(0);
        bytes memory expectedError = abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, receiver);
        vm.prank(bob);
        vm.expectRevert(expectedError);
        ourToken.transfer(address(0), transferAmount);
    }

    function test_TransferEventEmitted() external {
        uint256 transferAmount = 50 ether;
        vm.expectEmit(true, true, false, false);
        emit IERC20.Transfer(bob, alice, transferAmount);
        // vm.recordLogs();
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);
    }
    /*//////////////////////////////////////////////////////////////
                             ALLOWANCE TEST
    //////////////////////////////////////////////////////////////*/

    function test_CheckAllowanceWorks() external {
        uint256 initialAllowanceBalance = 1000;
        //Bob approves Alice to spend tokens
        vm.prank(bob);
        ourToken.approve(alice, initialAllowanceBalance);
        uint256 tranferAmount = 500;
        vm.prank(alice);
        //Alice will going to tranfer the allowed tokens from bob to x
        ourToken.transferFrom(bob, alice, tranferAmount);
        uint256 aliceBalance = ourToken.balanceOf(alice);
        uint256 bobBalance = ourToken.balanceOf(bob);
        uint256 aliceLeftAllowncefromBob = ourToken.allowance(bob, alice);
        assertEq(aliceBalance, tranferAmount);
        assertEq(aliceLeftAllowncefromBob, initialAllowanceBalance - tranferAmount);
        assertEq(bobBalance, STARTING_BALANCE - tranferAmount);
    }

    function testAllowanceInifiniteApproval() external {
        vm.prank(bob);
        ourToken.approve(alice, type(uint256).max);
        assertEq(ourToken.allowance(bob, alice), type(uint256).max);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, STARTING_BALANCE);

        assertEq(ourToken.allowance(bob, alice), type(uint256).max);
    }

    function testTransferFromWithInsufficientBalance() external {
        vm.prank(bob);
        ourToken.approve(alice, STARTING_BALANCE);

        vm.prank(alice);
        address spender = alice;
        uint256 allowance = STARTING_BALANCE;
        uint256 needed = STARTING_BALANCE + 1;

        bytes memory expectedError =
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, spender, allowance, needed);
        //expect revert when alice tries to move more funds than assigned
        vm.expectRevert(expectedError);
        ourToken.transferFrom(bob, alice, STARTING_BALANCE + 1);
    }

    function testApproveEventEmitted() external {
        vm.prank(bob);
        vm.expectEmit(true, true, false,false);
        emit IERC20.Approval(bob, alice,STARTING_BALANCE );
        ourToken.approve(alice, STARTING_BALANCE);
    }
    /*//////////////////////////////////////////////////////////////
                               EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function testSelfTransfer() external {
        uint bobInitialBalance = ourToken.balanceOf(bob);
        //bob is transfering funds to himself
        vm.prank(bob);
        ourToken.transfer(bob, STARTING_BALANCE);
        uint bobNewBalance = ourToken.balanceOf(bob);
        assertEq(bobInitialBalance, bobNewBalance);
    }

    function testSelfTransferFrom() external {
        vm.startPrank(bob);
        ourToken.approve(bob, STARTING_BALANCE);
        uint bobInitialBalance = ourToken.balanceOf(bob);
        ourToken.transferFrom(bob,bob, STARTING_BALANCE);
        vm.stopPrank();
        uint bobFinalBalance = ourToken.balanceOf(bob);
        assertEq(bobInitialBalance, bobFinalBalance);
    }

    function testTranfertoContract() external {
        address contractAddress  = address(new MockContract());
        vm.prank(bob);
        ourToken.transfer(contractAddress, STARTING_BALANCE);

        assertEq(ourToken.balanceOf(contractAddress), STARTING_BALANCE);
    }
    /*//////////////////////////////////////////////////////////////
                              MINTING TEST
    //////////////////////////////////////////////////////////////*/

    function testMintingTest() view external {
        assert(ourToken.balanceOf(DEFAULT_SENDER) == deployer.INITIAL_SUPPLY() - STARTING_BALANCE);
    }
}
