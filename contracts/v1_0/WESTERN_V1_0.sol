// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./RewardRun_V1_0.sol";

contract WESTERN_V1_0 is ERC20, Ownable {
  RewardRun_V1_0 public rewardRun;  

  struct Stake {
    uint256 id;
    uint256 creationTime;
    uint256 expireTime;
    uint256 balance;    
  }

  constructor(address owner, uint256 tokenCount) ERC20("WESTERN MONEY", "WESTERN") {
    _mint(owner, tokenCount * 10**18);
  }
}
