/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import { Harberger, Perwei } from "./Harberger.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

address constant admin = 0xee324c588ceF1BF1c1360883E4318834af66366d;
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

  address public controller;
  uint256 public collateral;
  uint256 public timestamp;

  // NOTE: We leave this ragequit function in for now as it allows an
  // administrator to shut down the contract when a new version is deployed, or
  // to slash a malicous ad publisher.
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
      if (msg.value < nextPrice + 1) {
        revert ErrValue();
      }

      address lastController = controller;
      title = _title;
      href = _href;
      controller = msg.sender;
      collateral = msg.value - nextPrice;
      timestamp = block.timestamp;

      (bool treasurySuccess,) = treasury.call{value: taxes}("");
      if (!treasurySuccess) {
        revert ErrCall();
      }
      // NOTE: We send the last controller double the amount of the current
      // price because one times the price is just their remaining collateral,
      // and another times the price is the buyer's transfer fee paid to take
      // possession over the ad during acquisition. The buyer's remaining
      // collateral (and hence the new price of the ad) is the message's value
      // minus the transfer fee.
      //
      // As this was a vulnerability in prior iterations of this contract, we
      // should also talk about what happens in the case that the buyer sends
      // so little in msg.value that it's roughly equal to the current price of
      // the ad.
      // In this case, the transfer fee (which is equal to the ad's current
      // price) is sent to the last controller, and the remainder = msg.value -
      // nextPrice is put up as the new collateral and hence is the new price.
      // And since this price is very low, the buyer takes on the risk of
      // having their ad being sold at a discount.
      lastController.call{value: nextPrice * 2}("");
      // NOTE2: We're not checking the success of this call because it could
      // lead to the last controller intentionally failing the call, hence
      // making the ad contract stuck.
    }
  }
}
