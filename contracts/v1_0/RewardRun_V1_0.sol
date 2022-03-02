// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./WESTERN_V1_0.sol";

contract RewardRun_V1_0 {
  using SafeMath for uint256;

  struct NestEntity {
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 expireTime;
    uint256 rewardsPerMinute;
    string name;
    uint256 created;
    uint256 isStake;
  }

  mapping(address => bool) public _managers;
  WESTERN_V1_0 public western;

  mapping(address => NestEntity[]) private _nestsOfUser;
  mapping(address => uint256) private _nestsCount;

  uint256 public nestPrice;

  uint256 public rewardsPerMinute;

  uint256 public totalNestsCreated = 0;

  uint256 public claimInterval = 60;


  event NestCreated(address indexed from, string name, uint256 index, uint256 totalNestsCreated);
  
  uint256 public nestLimit = 100;

  constructor(
    uint256 _nestPrice,                                    // 1000000000000000000            1
    uint256 _rewardsPerMinute                              
  ) {
    _managers[msg.sender] = true;
    nestPrice = _nestPrice;
    rewardsPerMinute = _rewardsPerMinute;
  }

  modifier onlyManager() {
    require(_managers[msg.sender] == true, "Only managers can call this function");
    _;
  }

  // external

  function _getRewardAmountOf(address account)
    external
    view
    returns (uint256)
  {
    require(isNestOwner(account), "GET REWARD OF: NO NEST OWNER");
    uint256 nestsCount;
    uint256 rewardCount = 0;

    NestEntity[] storage nests = _nestsOfUser[account];
    nestsCount = _nestsCount[account];

    NestEntity storage _nest;
    for (uint256 i = 0; i < nestsCount; i++) {
      _nest = nests[i];
      rewardCount += dividendsOwing(_nest);
    }

    return rewardCount;
  }

  function _getRewardAmountOf(address account, uint256 index)
    external
    view
    returns (uint256)
  {
    require(isNestOwner(account), "GET REWARD OF: NO NEST OWNER");
    NestEntity[] storage nests = _nestsOfUser[account];
    uint256 numberOfNests = _nestsCount[account];
    require(
      numberOfNests > 0,
      "CASHOUT ERROR: You don't have nests to cash-out"
    );
    NestEntity storage nest = _getNestByIndex(nests, index);
    uint256 rewardNest = dividendsOwing(nest);
    return rewardNest;
  }



  function getNests(address user) external view returns (NestEntity[] memory nests) {
		return _nestsOfUser[user];
	}

  function _getNestPrices() external view returns (uint256) {
    return (
      nestPrice
    );
  }

  function getNestPrice(uint256 _type, bool isFusion) external view returns (uint256 returnValue) {
    if (isFusion) {
    } else {
      if (_type == 1) {
          returnValue = nestPrice;
      }
    }
  }
  
  function _getNestNumberOf(address account) external view returns (uint256) {
    return _nestsCount[account];
  }

  function _isNestOwner(address account) external view returns (bool) {
    return isNestOwner(account);
  }

  // only manager

  function addManager(address manager) external onlyManager {
		_managers[manager] = true;
	}

  function updateNestLimit(uint256 newValue) external onlyManager {
    nestLimit = newValue;
  }

  function createNest(address account, string memory name, uint256 expireTime, uint256 _isStake) external onlyManager {
    require(_nestsCount[account] < nestLimit, "Can't create nests over 100");
    uint256 realExpireTime = 0;
    if (expireTime > 0) {
      realExpireTime = block.timestamp + expireTime;
    }
    uint256 rewards;

    if (_isStake == 0) {
        rewards = rewardsPerMinute;
    }
    _nestsOfUser[account].push(
      NestEntity({
        creationTime: block.timestamp,
        lastClaimTime: block.timestamp,
        expireTime: realExpireTime,
        rewardsPerMinute: rewards,
        name: name,
        created: 1,
        isStake: _isStake
      })
    );
    totalNestsCreated++;
    _nestsCount[account] ++;




		emit NestCreated(account, name, _nestsOfUser[account].length, totalNestsCreated);



    
  }

  function _cashoutNestReward(address account, uint256 index)
    external
    onlyManager
    returns (uint256)
  {
    NestEntity[] storage nests = _nestsOfUser[account];
    uint256 numberOfNests = _nestsCount[account];
    require(
        numberOfNests > 0,
        "CASHOUT ERROR: You don't have nests to cash-out"
    );
    NestEntity storage nest = _getNestByIndex(nests, index);
    uint256 rewardNest = dividendsOwing(nest);
    nest.lastClaimTime = block.timestamp;
    return rewardNest;
  }

  function _cashoutAllNestsReward(address account)
    external
    onlyManager
    returns (uint256)
  {
    NestEntity[] storage nests = _nestsOfUser[account];
    uint256 nestsCount = _nestsCount[account];
    require(nestsCount > 0, "NEST: NO NEST OWNER");
    NestEntity storage _nest;
    uint256 rewardsTotal = 0;
    for (uint256 i = 0; i < nestsCount; i++) {
      _nest = nests[i];
      uint256 rewardNest = dividendsOwing(_nest);
      rewardsTotal += rewardNest;
      _nest.lastClaimTime = block.timestamp;
    }
    return rewardsTotal;
  }

  function _changeNestPrice(uint256 newNestPrice) external onlyManager {
    nestPrice = newNestPrice;
  }

  function _changeRewardsPerMinute(uint256 newPrice) external onlyManager {
    rewardsPerMinute = newPrice;
  }

  function _changeClaimInterval(uint256 newInterval) external onlyManager {
    claimInterval = newInterval;
  }

  // Private

  function dividendsOwing(NestEntity memory nest) private view returns (uint256 availableRewards) {
		uint256 currentTime = block.timestamp;
		if (currentTime > nest.expireTime && nest.expireTime > 0) {
			currentTime = nest.expireTime;
		}
		uint256 minutesPassed = (currentTime).sub(nest.lastClaimTime).div(claimInterval);
    
    return minutesPassed.mul(nest.rewardsPerMinute);
    
	}

  function _checkExpired(NestEntity memory nest) private view returns (bool isExpired) {
		return (nest.expireTime > 0 && nest.expireTime <= block.timestamp);
	}

  function _getNestByIndex(
    NestEntity[] storage nests,
    uint256 index
  ) private view returns (NestEntity storage) {
    uint256 numberOfNests = nests.length;
    require(
        numberOfNests > 0,
        "CASHOUT ERROR: You don't have nests to cash-out"
    );
    require(index < numberOfNests, "CASHOUT ERROR: Invalid nest");
    return nests[index];
  }

  function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
        return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
        k = k - 1;
        uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  function isNestOwner(address account) private view returns (bool) {
      return _nestsCount[account] > 0;
  }

  // WESTERN

}
