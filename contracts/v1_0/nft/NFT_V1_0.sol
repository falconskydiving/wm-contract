// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT_V1_0 is ERC1155, Ownable {
  uint256 public constant MASTER = 0;
  uint256 public constant GRAND_MASTER = 1;

  constructor() ERC1155("") {
    _mint(msg.sender, MASTER, 1089, "");
    _mint(msg.sender, GRAND_MASTER, 33, "");
  }

  function mint(address account, uint256 id, uint256 amount) public onlyOwner {
    _mint(account, id, amount, "");
  }

  function burn(address account, uint256 id, uint256 amount) public {
    require(msg.sender == account);
    
    _burn(account, id, amount);
  }
}
