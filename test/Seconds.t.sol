/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.6;

import "forge-std/Test.sol";

import {Seconds} from "../src/Seconds.sol";
import {Ad} from "../src/Ad.sol";

contract UnauthorizedMinter {
  function mint(
    Seconds token,
    address _to,
    uint256 _value
  ) external {
    token.mint(_to, _value);
  }
}
contract SecondsTest is Test {
  receive() external payable {}

  Ad ad;
  Seconds token;
  function setUp() public {
    string memory name = "Seconds";
    string memory symbol = "SEC";
    uint8 decimals = 18;
    token = new Seconds(name, symbol, decimals);

    token.setAuthority(address(this));
  }

  function testSetNewAuthority() public {
    address newAuthority = address(0);
    token.setAuthority(newAuthority);
  }

  function testSetAuthorityUnauthorized() public {
    token.setAuthority(address(1337));

    address newOwner = address(0);
    token.transferOwnership(newOwner);
    vm.expectRevert("UNAUTHORIZED");
    token.setAuthority(address(this));
  }

  function testGuardedMintFunction() public {
    address to = address(this);
    uint256 value = 123;

    UnauthorizedMinter minter = new UnauthorizedMinter();
    vm.expectRevert(Seconds.ErrUnauthorized.selector);
    minter.mint(token, to, value);
  }

  function testCallWithdrawWithNoBalance() public {
    assertEq(token.balanceOf(address(this)), 0);

    uint256 value = 1;
    vm.expectRevert(Seconds.ErrValue.selector);
    token.withdraw(value);
  }

  function testMinting() public {
    address to = address(this);
    uint256 value = 123;
    token.mint(to, value);
    assertEq(token.balanceOf(to), value);
  }

  function testWithdrawHalf() public {
    payable(address(token)).transfer(1 ether);

    address to = address(this);
    uint256 value = 2;
    token.mint(to, value);
    assertEq(token.balanceOf(to), value);

    uint256 balance0 = address(this).balance;
    uint256 half = value/2;
    token.withdraw(half);

    assertEq(address(this).balance-balance0, 0.5 ether);
    assertEq(address(token).balance, 0.5 ether);
  }
}
