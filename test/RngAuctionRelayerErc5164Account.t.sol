// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { UD2x18 } from "prb-math/UD2x18.sol";
import { StartRngAuction, RngRequest } from "../src/StartRngAuction.sol";
import { IRngAuctionRelayListener } from "../src/interfaces/IRngAuctionRelayListener.sol";
import { AuctionResults } from "../src/interfaces/IAuction.sol";

import { RngRelayerBaseTest } from "./helpers/RngRelayerBaseTest.sol";

import { RngNotCompleted } from "../src/abstract/RngAuctionRelayer.sol";

import {
    RngAuctionRelayerErc5164Account,
    MessageDispatcherArbitrum,
    Erc5164Account,
    Erc5164AccountCallEncoder
} from "../src/RngAuctionRelayerErc5164Account.sol";

contract RngAuctionRelayerErc5164AccountTest is RngRelayerBaseTest {

    event RelayedToDispatcher(address indexed rewardRecipient, bytes32 indexed messageId);

    RngAuctionRelayerErc5164Account relayer;

    MessageDispatcherArbitrum messageDispatcher;
    Erc5164Account account;
    uint256 toChainId = 1;

    function setUp() public override {
        super.setUp();
        messageDispatcher = MessageDispatcherArbitrum(makeAddr("messageDispatcher"));
        account = Erc5164Account(makeAddr("account"));

        relayer = new RngAuctionRelayerErc5164Account(
            startRngAuction,
            rngAuctionRelayListener,
            messageDispatcher,
            account,
            toChainId
        );
    }

    function testConstructor() public {
        assertEq(address(relayer.startRngAuction()), address(startRngAuction));
        assertEq(address(relayer.rngAuctionRelayListener()), address(rngAuctionRelayListener));
        assertEq(address(relayer.messageDispatcher()), address(messageDispatcher));
        assertEq(address(relayer.account()), address(account));
        assertEq(relayer.toChainId(), toChainId);
    }

    function testRelay_happyPath() public {
        mockIsRngComplete(true);
        mockRngResults(123, 456);
        mockAuctionResults(address(this), UD2x18.wrap(0.5 ether));
        mockCurrentSequenceId(789);

        vm.mockCall(
            address(messageDispatcher),
            abi.encodeWithSelector(
                messageDispatcher.dispatchMessage.selector,
                toChainId,
                address(account),
                Erc5164AccountCallEncoder.encodeCalldata(
                    address(rngAuctionRelayListener),
                    0,
                    abi.encodeWithSelector(
                        rngAuctionRelayListener.rngComplete.selector,
                        123, 456, address(this), 789, AuctionResults(address(this), UD2x18.wrap(0.5 ether))
                    )
                )
            ),
            abi.encode(bytes32(uint(9999)))
        );

        vm.expectEmit(true, true, false, false);

        emit RelayedToDispatcher(address(this), bytes32(uint(9999)));
        assertEq(relayer.relay(address(this)), bytes32(uint(9999)));
    }

}
