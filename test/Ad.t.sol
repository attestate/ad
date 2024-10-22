/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import { Ad, denominator, treasury } from "../src/Ad.sol";
import { Seconds } from "../src/Seconds.sol";

contract Setter {
  receive() external payable {}
  function set(
    Ad ad,
    string calldata title,
    string calldata href,
    uint256 value
  ) external {
    ad.set{value: value}(title, href);
  }
}

contract AdTest is Test {
  Ad ad;
  Seconds token;
  receive() external payable {}

  function setUp() public {
    string memory name = "TIME";
    string memory symbol = "TIME";
    uint8 decimals = 18;
    token = new Seconds(name, symbol, decimals);

    ad = new Ad(address(token));

    token.setAuthority(address(ad));
  }

  function testSetForFree(uint96 value) public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    ad.set{value: value}(title, href);
  }

  function testReSetForFree() public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    ad.set{value: 0}(title, href);
    assertEq(ad.controller(), address(this));
    assertEq(ad.collateral(), 0);
    assertEq(ad.timestamp(), block.timestamp);

    (uint256 price, uint256 taxes) = ad.price();
    assertEq(price, 0);
    assertEq(taxes, 0);
    Setter setter = new Setter();
    uint256 setterValue = 2;
    payable(address(setter)).transfer(setterValue);

    uint256 balance0 = address(this).balance;
    setter.set(ad, title, href, setterValue);

    assertEq(token.balanceOf(address(this)), 0);
    assertEq(address(token).balance, 1);
    uint256 balance1 = address(this).balance;
    assertEq(balance1 - balance0, 0);
    assertEq(ad.controller(), address(setter));
    assertEq(ad.collateral(), 1);
    assertEq(ad.timestamp(), block.timestamp);
  }

  function testReSetForTooLowPrice() public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    uint256 value = 2;
    ad.set{value: value}(title, href);

    (uint256 price, uint256 taxes) = ad.price();
    assertEq(price, 2);
    assertEq(taxes, 0);

    Setter setter = new Setter();
    payable(address(setter)).transfer(1 ether);
    vm.expectRevert(Ad.ErrValue.selector);
    uint256 setterValue = 3;
    setter.set(ad, title, href, setterValue);
  }

  function testSet(uint96 value) public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    ad.set{value: value}(title, href);

    assertEq(ad.controller(), address(this));
    assertEq(ad.collateral(), value);
    assertEq(ad.timestamp(), block.timestamp);
  }

  function testTaxationAfterAMonth(uint96 value) public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    ad.set{value: value}(title, href);

    uint256 collateral0 = ad.collateral();
    assertEq(ad.controller(), address(this));
    assertEq(collateral0, value);
    assertEq(ad.timestamp(), block.timestamp);

    vm.warp(block.timestamp+2629800); // 2629800s are a month

    (uint256 nextPrice1, uint256 taxes1) = ad.price();
    assertEq(nextPrice1, 0);
    assertEq(taxes1, ad.collateral());
  }

  function testReSetForLowerPrice() public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    uint256 value = denominator;
    ad.set{value: value}(title, href);

    uint256 collateral0 = ad.collateral();
    assertEq(ad.controller(), address(this));
    assertEq(collateral0, value);
    assertEq(ad.timestamp(), block.timestamp);

    vm.warp(block.timestamp+1);

    (uint256 nextPrice1, uint256 taxes1) = ad.price();
    assertEq(nextPrice1, ad.collateral()-1);
    assertEq(taxes1, 1);

    Setter setter = new Setter();
    payable(address(setter)).transfer(1 ether);
    vm.expectRevert(Ad.ErrValue.selector);
    uint256 setterValue = collateral0-3;
    setter.set(ad, title, href, setterValue);
  }

  function testReSet(uint96 setterValue) public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    uint256 value = denominator;
    ad.set{value: value}(title, href);

    uint256 collateral0 = ad.collateral();
    assertEq(ad.controller(), address(this));
    assertEq(collateral0, value);
    assertEq(ad.timestamp(), block.timestamp);

    vm.warp(block.timestamp+1);

    (uint256 nextPrice1, uint256 taxes1) = ad.price();
    assertEq(nextPrice1, ad.collateral()-1);
    assertEq(taxes1, 1);

    vm.assume(setterValue > denominator);
    vm.assume(setterValue < 1_000_000_000_000);
    vm.assume(setterValue % 2 == 0);
    Setter setter = new Setter();
    payable(address(setter)).transfer(setterValue);
    uint256 balance0 = address(this).balance;

    setter.set(ad, title, href, setterValue);

    assertEq(token.balanceOf(address(this)), 1);
    assertEq(address(token).balance, (setterValue - denominator) / 2);

    uint256 difference = setterValue - nextPrice1;
    uint256 markup = difference / 2;
    uint256 balance1 = address(this).balance;
    assertEq(balance1 - balance0, nextPrice1);

    uint256 collateral1 = ad.collateral();
    assertEq(ad.controller(), address(setter));
    assertEq(collateral1, setterValue - markup);
    assertEq(ad.timestamp(), block.timestamp);
  }

  function testRedeemForETH(uint96 setterValue) public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    uint256 value = denominator;
    ad.set{value: value}(title, href);

    uint256 collateral0 = ad.collateral();
    assertEq(ad.controller(), address(this));
    assertEq(collateral0, value);
    assertEq(ad.timestamp(), block.timestamp);

    vm.warp(block.timestamp+1);

    (uint256 nextPrice1, uint256 taxes1) = ad.price();
    assertEq(nextPrice1, ad.collateral()-1);
    assertEq(taxes1, 1);

    vm.assume(setterValue > denominator);
    vm.assume(setterValue < 1_000_000_000_000);
    vm.assume(setterValue % 2 == 0);
    Setter setter = new Setter();
    payable(address(setter)).transfer(setterValue);
    uint256 balance0 = address(this).balance;

    setter.set(ad, title, href, setterValue);

    assertEq(token.balanceOf(address(this)), 1);
    assertEq(address(token).balance, (setterValue - denominator) / 2);

    uint256 tokenBalance = 1;
    uint256 amount = token.share(tokenBalance);
    assertEq(token.totalSupply(), tokenBalance);
    assertEq(amount, address(token).balance);

    uint256 tokenETHBalance = address(token).balance;
    uint256 balance1 = address(this).balance;
    token.withdraw(tokenBalance);
    assertEq(address(token).balance, 0);
    assertEq(address(this).balance, balance1+tokenETHBalance);
  }
}
