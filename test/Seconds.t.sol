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

  function testCallWithdrawWithNoBalance(uint256 value) public {
    assertEq(token.balanceOf(address(this)), 0);

    vm.expectRevert(Seconds.ErrValue.selector);
    token.withdraw(value);
  }

  function testMinting(uint256 value) public {
    address to = address(this);
    token.mint(to, value);
    assertEq(token.balanceOf(to), value);
  }

  function testWithdrawAll(uint256 value, uint96 balanceValue) public {
    payable(address(token)).transfer(balanceValue);

    address to = address(this);
    token.mint(to, value);
    assertEq(token.balanceOf(to), value);

    uint256 preBalance = address(this).balance;
    assertEq(token.balanceOf(address(this)), value);
    vm.assume(balanceValue != 0);
    vm.assume(value != 0);
    vm.assume(value < 60 * 60 * 24 * 365 * 10000);
    uint256 amount = token.share(value);
    token.withdraw(value);

    assertEq(token.balanceOf(address(this)), 0);
    assertEq(address(this).balance-preBalance, balanceValue);
    assertEq(address(token).balance, 0);
  }
}
