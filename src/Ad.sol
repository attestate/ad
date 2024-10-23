/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Harberger, Perwei } from "./Harberger.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

interface IERC20 {
  function mint(address to, uint256 value) external;
}

address constant treasury = 0x1337E2624ffEC537087c6774e9A18031CFEAf0a9;
// NOTE: The tax rate is 1/2629742 per second. The denominator (2629743) is
// seconds in a month. 
// 1 month (avg. 30.44 days) = 2_629_743
// We subtract a second to have an even number.
// Practically, it means that a self-assessed key worth 1
// ether will accumulate a tax obligation of 1 ether/month.
uint256 constant numerator    = 1;
uint256 constant denominator  = 2629742;
// TODO: Add a function that allows to shut down this contract gracefully in
// case of an update, by e.g. allowing an admit to call a function that sends
// the leftover collateral to the lastController.
contract Ad is ReentrancyGuard {
  error ErrValue();
  error ErrUnauthorized();
  error ErrCall();

  string public title;
  string public href;

  address public token;

  address public controller;
  uint256 public collateral;
  uint256 public timestamp;

  constructor(address _token) {
    token = _token;
  }

  function price() public view returns (uint256 nextPrice, uint256 taxes) {
    return Harberger.getNextPrice(
      Perwei(numerator, denominator),
      block.timestamp - timestamp,
      collateral
    );
  }

  function set(
    string calldata _title,
    string calldata _href
  ) nonReentrant external payable {
    if (controller == address(0)) {
      title = _title;
      href = _href;
      controller = msg.sender;
      collateral = msg.value;
      timestamp = block.timestamp;
    } else {
      // NOTE on the calculation of the markup: The term "markup" refers to the
      // buyer premium, which is the difference between the last price
      // (nextPrice) and the new price (msg.value).
      //
      // In this contract, the markup is divided by two for two reasons:
      //
      // 1. Half is sent to the token contract to reward the previous ad owner.
      // 2. The other half ensures there is enough collateral to cover the tax
      // obligations.
      //
      //
      // Therefore, `msg.value` must be at least `nextPrice + 2 Wei`:
      //
      // - 1 Wei for the premium sent to the token contract.
      // - 1 Wei to maintain sufficient collateral for taxation.
      //
      // This setup ensures both incentive alignment and compliance with tax
      // obligations.
      (uint256 nextPrice, uint256 taxes) = price();
      if (msg.value < nextPrice+2) {
        revert ErrValue();
      }

      uint256 difference = msg.value-nextPrice;
      uint256 markup = difference/2;
      uint256 timeDifference = block.timestamp - timestamp;

      address lastController = controller;
      title = _title;
      href = _href;
      controller = msg.sender;
      collateral = msg.value-markup;
      timestamp = block.timestamp;

      (bool treasurySuccess,) = treasury.call{value: taxes}("");
      (bool tokenSuccess,) = token.call{value: markup}("");
      if (!treasurySuccess || !tokenSuccess) {
        revert ErrCall();
      }
      lastController.call{value: nextPrice}("");

      IERC20(token).mint(lastController, timeDifference);
    }
  }
}
