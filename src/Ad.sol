/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Harberger, Perwei } from "./Harberger.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

interface IERC20 {
  function mint(address to, uint256 value) external;
}

address constant treasury = 0x1337E2624ffEC537087c6774e9A18031CFEAf0a9;
// NOTE: The tax rate is 1/2629743 per second. The denominator (2629743) is
// seconds in a month. 
// 1 month (avg. 30.44 days) = 2_629_743
// Practically, it means that a self-assessed key worth 1
// ether will accumulate a tax obligation of 1 ether/month.
uint256 constant numerator    = 1;
uint256 constant denominator  = 2629743;
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
