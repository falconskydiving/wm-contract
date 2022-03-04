// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WESTERN_V1_0.sol";

contract RewardRun_V1_0 is Ownable {
  using SafeMath for uint256;

  struct Stake {
    uint256 index;
    uint256 balance;
    uint256 creationTime;
  }

  struct NestEntity {
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 rewardsPerMinute;
    bool created;
    bool isStake;
  }

  mapping(address => bool) public _managers;
  WESTERN_V1_0 public western;

  mapping(address => Stake[]) public stakesofAccount;
  

  mapping(address => NestEntity[]) private _nestsOfAccount;
  mapping(address => uint256) private _nestsCount;

  address public rewardsPool;
	address public liquidityPool;
  address public treasury;

  uint256 public rewardsPoolFee;
  uint256 public liquidityPoolFee;
  uint256 public treasuryFee;

  uint256 public nestPrice;                         // 10000000000000000000 / 10 WESTERN
  uint256 public rewardsPerMinuteNest;              // 156250000000000 0.00015625 per minite /  0.225 FIRE daily

  uint256 public nestLimit = 100;

  uint256 public totalStakesCreated = 0;
  uint256 public totalNestsCreated = 0;
  
  uint256 public claimInterval = 60;

  event NestCreated(address indexed from, uint256 index, uint256 totalNestsCreated);

  constructor(
    uint256 _nestPrice,
    uint256 _rewardsPerMinuteNest,
    address[] memory addresses,
    uint256[] memory fees
  ) {
    _managers[msg.sender] = true;
    nestPrice = _nestPrice;
    rewardsPerMinuteNest = _rewardsPerMinuteNest;
    
    rewardsPool = addresses[0];
    liquidityPool = addresses[1];
    treasury = addresses[2];

    rewardsPoolFee = fees[0];           // 7
    liquidityPoolFee = fees[1];         // 1
    treasuryFee = fees[2];              // 2
  }

  modifier onlyManager() {
    require(_managers[msg.sender] == true, "Only managers can call this function");
    _;
  }

  // external

  function getNests(address account) external view returns (NestEntity[] memory) {
		return _nestsOfAccount[account];
	}

  function getNestPrice() private view returns (uint256) {
    return nestPrice;
  }
  
  function _getNestNumberOf(address account) external view returns (uint256) {
    return _nestsCount[account];
  }

  function _isNestOwner(address account) external view returns (bool) {
    return isNestOwner(account);
  }

  function createNodeWithStake() external {
    address sender = msg.sender;

    require(sender != address(0), "ZERO ADDRESS");
    require(
      sender != rewardsPool && sender != liquidityPool && sender != treasury, 
      "CANNOT CREATE NODE"
    );

    uint256 _nestPrice = getNestPrice();
    require(western.balanceOf(sender) >= _nestPrice, "BALANCE TOO LOW");

    western.transferFrom(sender, rewardsPool, _nestPrice);
    western.transferFrom(rewardsPool, liquidityPool, _nestPrice.mul(liquidityPoolFee).div(100));
    western.transferFrom(rewardsPool, treasury, _nestPrice.mul(treasuryFee).div(100));

    _createStake(_nestPrice);
    _createNest(sender);
  }

  function cashoutReward(uint256 index) external {
    address sender = msg.sender;

    require(sender != address(0), "ZERO ADDRESS");
    require(
      sender != rewardsPool && sender != liquidityPool && sender != treasury,
      "CANNOT CASHOUT REWARDS"
    );
    uint256 rewardAmount = _getRewardAmountOf(sender, index);
    require(
      rewardAmount > 0,
      "NOT ENOUGH REWARD TO CASH OUT"
    );

    western.transferFrom(rewardsPool, sender, rewardAmount);
    _cashoutNestReward(sender, index);
  }

  function cashoutAllReward() external {
    address sender = msg.sender;

    require(sender != address(0), "ZERO ADDRESS");
    require(
      sender != rewardsPool && sender != liquidityPool && sender != treasury,
      "CANNOT CASHOUT REWARDS"
    );
    
    uint256 rewardAmount = _getRewardAmountOf(sender);
    require(
      rewardAmount > 0,
      "NOT ENOUGH TO CASH OUT"
    );

    western.transferFrom(rewardsPool, sender, rewardAmount);
    _cashoutAllNestsReward(sender);
  }

  function withdrawStaking(uint256 index) external {
		address staker = msg.sender;

		Stake storage stake = stakesofAccount[staker][index];
		require(stake.balance > 0, "NOTHING TO CLAIM");
		
		uint256 amount = stake.balance;
		stake.balance = 0;
		western.transferFrom(rewardsPool, staker, amount);
	}

  // only manager

  function addManager(address manager) external onlyManager {
		_managers[manager] = true;
	}

  function updateNestLimit(uint256 newNestLimit) external onlyManager {
    nestLimit = newNestLimit;
  }

  function _createStake(uint256 amount) private {
		address staker = msg.sender;
		
		uint256 stakeIndex = totalStakesCreated++;
		stakesofAccount[staker].push(
			Stake({
        index: stakeIndex,
        balance: amount,
				creationTime: block.timestamp
			})
		);
	} 

  function _changeNestPrice(uint256 newNestPrice) external onlyManager {
    nestPrice = newNestPrice;
  }

  function _changeRewardsPerMinute(uint256 newRewards) external onlyManager {
    rewardsPerMinuteNest = newRewards;
  }

  function _changeClaimInterval(uint256 newInterval) external onlyManager {
    claimInterval = newInterval;
  }

  // Private

  function _getRewardAmountOf(address account)
    private
    view
    returns (uint256)
  {
    require(isNestOwner(account), "GET REWARD OF: NO NEST OWNER");
    uint256 nestsCount;
    uint256 rewardCount = 0;

    NestEntity[] storage nests = _nestsOfAccount[account];
    nestsCount = _nestsCount[account];

    NestEntity storage _nest;
    for (uint256 i = 0; i < nestsCount; i++) {
      _nest = nests[i];
      rewardCount += dividendsOwing(_nest);
    }

    return rewardCount;
  }

  function _getRewardAmountOf(address account, uint256 index)
    private
    view
    returns (uint256)
  {
    require(isNestOwner(account), "GET REWARD OF: NO NEST OWNER");
    NestEntity[] storage nests = _nestsOfAccount[account];
    uint256 numberOfNests = _nestsCount[account];
    require(
      numberOfNests > 0,
      "CASHOUT ERROR: You don't have nests to cash-out"
    );
    NestEntity storage nest = _getNestByIndex(nests, index);
    uint256 rewardNest = dividendsOwing(nest);
    return rewardNest;
  }

  function _createNest(address account) private onlyManager {
    require(_nestsCount[account] < nestLimit, "Can't create nests over 100");
    uint256 rewardsPerMinute;
    
    // check if a staker purchase a nft
    // ...

    rewardsPerMinute = rewardsPerMinuteNest;

    _nestsOfAccount[account].push(
      NestEntity({
        creationTime: block.timestamp,
        lastClaimTime: block.timestamp,
        rewardsPerMinute: rewardsPerMinute,
        created: true,
        isStake: true
      })
    );

    totalNestsCreated++;
    _nestsCount[account] ++;
		emit NestCreated(account, _nestsOfAccount[account].length, totalNestsCreated);
  }

  function _cashoutNestReward(address account, uint256 index) private onlyManager {
    NestEntity[] storage nests = _nestsOfAccount[account];
    uint256 numberOfNests = _nestsCount[account];
    require(
      numberOfNests > 0,
      "CASHOUT ERROR: You don't have nests to cash-out"
    );
    NestEntity storage nest = _getNestByIndex(nests, index);
    nest.lastClaimTime = block.timestamp;
  }

  function _cashoutAllNestsReward(address account) private onlyManager
  {
    NestEntity[] storage nests = _nestsOfAccount[account];
    uint256 nestsCount = _nestsCount[account];
    require(nestsCount > 0, "NEST: NO NEST OWNER");

    NestEntity storage _nest;
    for (uint256 i = 0; i < nestsCount; i++) {
      _nest = nests[i];
      _nest.lastClaimTime = block.timestamp;
    }
  }

  function dividendsOwing(NestEntity memory nest) private view returns (uint256 availableRewards) {
		uint256 currentTime = block.timestamp;

		uint256 minutesPassed = (currentTime).sub(nest.lastClaimTime).div(claimInterval);
    if (nest.lastClaimTime == nest.creationTime) {
      return uint256(0);
    } else {
      return minutesPassed.mul(nest.rewardsPerMinute);
    }
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

  function isNestOwner(address account) private view returns (bool) {
    return _nestsCount[account] > 0;
  }
}
