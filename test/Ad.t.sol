/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import { Ad, denominator, treasury, admin } from "../src/Ad.sol";

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
  receive() external payable {}

  function setUp() public {
    ad = new Ad();
  }

  function testSetForOneMore(uint96 value) public {
    // NOTE: There can only be maxvalue(uint96) Ether in the Ethereum system.
    // However, the ad requires the transfer fee to be both present in the
    // existing collateral, and as the transfer fee sent from the buyer. So
    // value must maximally ever reach half of maxvalue(uint96) as it has to be
    // present twice at one time. You can test this assumption by adding + 1 to
    // (2**96) / 2 (the test will then fail).
    vm.assume(value < (2**96) / 2);
    string memory title = "Hello world";
    string memory href = "https://example.com";
    ad.set{value: value}(title, href);

    assertEq(ad.controller(), address(this));
    assertEq(ad.collateral(), value);
    assertEq(ad.timestamp(), block.timestamp);

    (uint256 nextPrice, uint256 taxes) = ad.price();
    assertEq(nextPrice, value); 
    assertEq(taxes, 0); 

    ad.set{value: value + 1}(title, href);

    (uint256 nextPrice1, uint256 taxes1) = ad.price();
    assertEq(nextPrice1, 1); 
    assertEq(taxes1, 0); 

    assertEq(ad.controller(), address(this));
    assertEq(ad.timestamp(), block.timestamp);
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
    payable(address(setter)).transfer(1 ether);
    uint256 setterValue = 1;
    uint256 balanceBeforeSet = address(this).balance;
    setter.set(ad, title, href, setterValue);
    uint256 balanceAfterSet = address(this).balance;
    assertEq(balanceBeforeSet, balanceAfterSet);
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
    uint256 setterValue = 1;
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

  function testReSet() public {
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
    uint256 balance0 = address(this).balance;
    uint256 setterValue = ad.collateral();
    setter.set(ad, title, href, setterValue);
    uint256 balance1 = address(this).balance;
    assertEq(balance1 - balance0, nextPrice1*2);


    uint256 collateral1 = ad.collateral();
    assertEq(ad.controller(), address(setter));
    assertEq(collateral1, setterValue-nextPrice1);
    assertEq(ad.timestamp(), block.timestamp);
  }

  function testRagequitUnauthorized() public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    uint256 value = 1;
    ad.set{value: value}(title, href);

    vm.expectRevert(Ad.ErrUnauthorized.selector);
    ad.ragequit();
  }

  function testRagequitAsAdmin() public {
    string memory title = "Hello world";
    string memory href = "https://example.com";
    uint256 value = 1;
    ad.set{value: value}(title, href);

    uint256 balance0 = admin.balance;

    vm.prank(admin);
    ad.ragequit();

    uint256 balance1 = admin.balance;
    assertEq(balance0+value, balance1);
  }
}
