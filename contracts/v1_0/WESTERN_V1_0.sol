// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./RewardRun_V1_0.sol";

contract WESTERN_V1_0 is ERC20, Ownable {
  constructor(address owner, uint256 tokenCount) ERC20("WESTERN MONEY", "WESTERN") {
    super._mint(owner, tokenCount * 10**18);
  }
}
