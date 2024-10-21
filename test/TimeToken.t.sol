/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import {TimeToken} from "../src/TimeToken.sol";
import {Ad} from "../src/Ad.sol";

contract TimeTokenTest is Test {
  Ad ad;
  TimeToken tt;
  function setUp() public {
    string memory name = "TIME";
    string memory symbol = "TIME";
    uint8 decimals = 18;

    ad = new Ad();
    address authority = address(ad);

    tt = new TimeToken(name, symbol, decimals, authority);
  }

  function testMinting() public {
  }
}
