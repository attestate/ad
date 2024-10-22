pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";
import {Owned} from "./Owned.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {FixedPointMathLib} from "./FixedPointMathLib.sol";

contract Seconds is ERC20, Owned(msg.sender), ReentrancyGuard {
  address public authority;
  error ErrUnauthorized();
  error ErrValue();
  error ErrCall();

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol, _decimals) {}

  receive() external payable {}

  function setAuthority(address _newAuthority) public onlyOwner {
    authority = _newAuthority;
  }

  function share(
    uint256 _value
  ) public view returns(uint256 balance) {
    uint256 amount = FixedPointMathLib.fdiv(
      _value * address(this).balance,
      totalSupply * FixedPointMathLib.WAD,
      FixedPointMathLib.WAD
    );
    return amount;
  }

  function withdraw(uint256 _value) public nonReentrant {
    if (_value > balanceOf[msg.sender] || _value == 0) {
      revert ErrValue();
    }

    // NOTE: We have to calculate `share` before calling `_burn` as it alters
    // the `totalSupply` value.
    uint256 amount = share(_value);

    _burn(msg.sender, _value);

    (bool result,) = msg.sender.call{value: amount}("");
    if (!result) {
      revert ErrCall();
    }
  }

  function mint(address _to, uint256 _value) public virtual {
    if (msg.sender != authority) {
      revert ErrUnauthorized();
    }
    _mint(_to, _value);
  }
}
