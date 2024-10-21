pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";
import {Owned} from "./Owned.sol";

contract TimeToken is ERC20, Owned(msg.sender) {
  address public authority;
  error ErrUnauthorized();

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    address _authority
  ) ERC20(_name, _symbol, _decimals) {
    authority = _authority;
  }

  function setAuthority(address _newAuthority) public onlyOwner {
    authority = _newAuthority;
  }

  function mint(address to, uint256 value) public virtual {
    if (msg.sender != authority) {
      revert ErrUnauthorized();
    }
    _mint(to, value);
  }

  function burn(address from, uint256 value) public virtual {
    if (msg.sender != authority) {
      revert ErrUnauthorized();
    }
    _burn(from, value);
  }
}
