/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Harberger, Perwei } from "./Harberger.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

address constant treasury = 0x1337E2624ffEC537087c6774e9A18031CFEAf0a9;
address constant admin = 0xee324c588ceF1BF1c1360883E4318834af66366d;
// NOTE: The tax rate is 1/31556952 per year. The denominator (31556952) is
// seconds in a year. Practically, it means that a self-assessed key worth 1
// ether will accumulate a tax obligation of 1 ether/year.
uint256 constant numerator    = 1;
uint256 constant denominator  = 31556952;
contract Ad is ReentrancyGuard {
  error ErrValue();
  error ErrUnauthorized();

  string public title;
  string public href;

  address public controller;
  uint256 public collateral;
  uint256 public timestamp;

  function ragequit() external {
    if (msg.sender != admin) {
      revert ErrUnauthorized();
    }

    admin.call{value: address(this).balance}("");
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

      address lastController = controller;
      title = _title;
      href = _href;
      controller = msg.sender;
      collateral = msg.value-markup;
      timestamp = block.timestamp;

      treasury.call{value: taxes}("");
      lastController.call{value: nextPrice+markup}("");
    }
  }
}
