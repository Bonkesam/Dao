// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MyGovenor} from "../src/MyGovenor.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Box} from "../src/Box.sol";

contract MyGovernorTest is Test {
    GovToken token;
    TimelockController timelock;
    MyGovenor governor;
    Box box;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    // These values should match what you set in your Governor constructor
    uint256 public constant VOTING_DELAY = 1 days; // How long till a proposal vote becomes active
    uint256 public constant VOTING_PERIOD = 1 weeks; // How long voting lasts
    uint256 public constant PROPOSAL_THRESHOLD = 0; // Minimum amount of votes needed to create a proposal

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public constant VOTER = address(1);

    function setUp() public {
        token = new GovToken();

        //Mint token to voter
        vm.prank(address(this));
        token.mint(VOTER, 100e18);

        //Voter delegates voting power to themselves
        vm.prank(VOTER);
        token.delegate(VOTER);

        //setup roles for timelock
        //Empty arrays mean no proposers or executors at initialization
        timelock = new TimelockController(
            MIN_DELAY,
            proposers,
            executors,
            address(this)
        );

        //Initialize Govenor
        governor = new MyGovenor(token, timelock);

        // Set up roles - governor becomes proposer, anyone can execute, revoke admin role
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE(); // Changed from TIMELOCK_ADMIN_ROLE

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // Anyone can execute
        timelock.revokeRole(adminRole, address(this));

        //setup Box contract and transfer ownership to timelock
        box = new Box(address(this));
        box.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 777;
        string memory description = "Store 777 in Box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature(
            "store(uint256)",
            valueToStore
        );
        addressesToCall.push(address(box));
        values.push(0);
        functionCalls.push(encodedFunctionCall);

        // 1. Propose to the DAO
        uint256 proposalId = governor.propose(
            addressesToCall,
            values,
            functionCalls,
            description
        );

        console.log("Proposal State:", uint256(governor.state(proposalId)));
        // governor.proposalSnapshot(proposalId)
        // governor.proposalDeadline(proposalId)

        //Move time forward to pass the voting delay
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 2. Vote
        string memory reason = "I like a do da cha cha";

        // 0 = Against, 1 = For, 2 = Abstain for this example
        uint8 voteWay = 1;
        vm.prank(VOTER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        //Move time forward to pass the voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 3. Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(addressesToCall, values, functionCalls, descriptionHash);

        //Move time forward to pass the timelock delay
        vm.roll(block.number + MIN_DELAY + 1);
        vm.warp(block.timestamp + MIN_DELAY + 1);

        // 4. Execute
        governor.execute(
            addressesToCall,
            values,
            functionCalls,
            descriptionHash
        );

        assert(box.retrieve() == valueToStore);
    }
}
