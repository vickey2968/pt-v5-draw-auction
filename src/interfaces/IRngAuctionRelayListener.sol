// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AuctionResult } from "./IAuction.sol";

/// @title IRngAuctionRelayListener
/// @author G9 Software Inc.
/// @notice Interface to receive RNG auction relays
interface IRngAuctionRelayListener {

    /// @notice Called by the relayer when the RNG auction is complete
    /// @param randomNumber The random number generated by the RNG auction
    /// @param rngCompletedAt The timestamp when the RNG service delivered the random number
    /// @param rewardRecipient The address of the recipient for the relay reward
    /// @param sequenceId The sequence id of the RNG auction
    /// @return any custom data it likes to track the relay.
    function rngComplete(
        uint256 randomNumber,
        uint256 rngCompletedAt,
        address rewardRecipient,
        uint32 sequenceId,
        AuctionResult calldata auctionResult
    ) external returns (bytes32);
}
