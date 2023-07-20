// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import { UD2x18 } from "prb-math/UD2x18.sol";

import { AuctionResults } from "local-draw-auction/interfaces/IAuction.sol";

import { RewardLibWrapper } from "test/wrappers/RewardLibWrapper.sol";

contract RewardLibTest is Test {
  RewardLibWrapper public rewardLib;

  function setUp() external {
    rewardLib = new RewardLibWrapper();
  }

  function testRewardPortion_zeroElapsed() external {
    assertEq(UD2x18.unwrap(rewardLib.rewardPortion(0, 1 days)), 0); // 0
  }

  function testRewardPortion_fullElapsed() external {
    assertEq(UD2x18.unwrap(rewardLib.rewardPortion(1 days, 1 days)), 1e18); // 1
  }

  function testRewardPortion_halfElapsed() external {
    assertEq(UD2x18.unwrap(rewardLib.rewardPortion(1 days / 2, 1 days)), 5e17); // 0.5
  }

  function testReward_noRecipient() external {
    AuctionResults memory _auctionResults = AuctionResults(
      address(0), // no recipient
      UD2x18.wrap(5e17) // 0.5
    );
    uint256 _reserve = 1e18;
    assertGt(_reserve, 0);
    assertGt(UD2x18.unwrap(_auctionResults.rewardPortion), 0);
    assertEq(rewardLib.reward(_auctionResults, _reserve), 0);
  }

  function testReward_zeroReserve() external {
    AuctionResults memory _auctionResults = AuctionResults(
      address(this),
      UD2x18.wrap(5e17) // 0.5
    );
    uint256 _reserve = 0; // no reserve
    assertNotEq(_auctionResults.recipient, address(0));
    assertGt(UD2x18.unwrap(_auctionResults.rewardPortion), 0);
    assertEq(rewardLib.reward(_auctionResults, _reserve), 0);
  }

  function testReward_zeroPortion() external {
    AuctionResults memory _auctionResults = AuctionResults(
      address(this),
      UD2x18.wrap(0) // 0
    );
    uint256 _reserve = 1e18;
    assertGt(_reserve, 0);
    assertNotEq(_auctionResults.recipient, address(0));
    assertEq(rewardLib.reward(_auctionResults, _reserve), 0);
  }

  function testReward_fullPortion() external {
    AuctionResults memory _auctionResults = AuctionResults(
      address(this),
      UD2x18.wrap(1e18) // full portion (1.0)
    );
    uint256 _reserve = 1e18;
    assertEq(rewardLib.reward(_auctionResults, _reserve), _reserve);
  }

  function testReward_halfPortion() external {
    AuctionResults memory _auctionResults = AuctionResults(
      address(this),
      UD2x18.wrap(5e17) // half portion (0.5)
    );
    uint256 _reserve = 1e18;
    assertEq(rewardLib.reward(_auctionResults, _reserve), _reserve / 2);
  }

  function testRewards() external {
    AuctionResults[] memory _auctionResults = new AuctionResults[](3);
    _auctionResults[0] = AuctionResults(address(this), UD2x18.wrap(0)); // 0 reward (0 portion of 1e18), 1e18 reserve remains
    _auctionResults[1] = AuctionResults(address(this), UD2x18.wrap(75e16)); // 75e16 reward (0.75 portion of 1e18), 25e16 reserve remains
    _auctionResults[2] = AuctionResults(address(this), UD2x18.wrap(1e18)); // 25e16 reward (1.0 portion of 25e16), 0 reserve remains
    uint256[] memory _rewards = rewardLib.rewards(_auctionResults, 1e18);
    assertEq(_rewards[0], 0);
    assertEq(_rewards[1], 75e16);
    assertEq(_rewards[2], 25e16);
  }
}
