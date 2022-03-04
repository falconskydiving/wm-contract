const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RewardRun", function () {
  it("Should deploy the contracts", async function () {
    const [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();

    /* deploy the western contract */
    
    const Western  = await ethers.getContractFactory("WESTERN_V1_0")
    const western = await Western.deploy(addr1.address, 1000000)
    await western.deployed()
    const westernAddress = western.address

    console.log('western address: ', westernAddress);
    console.log('western balanceOf: ', await western.balanceOf(addr1.address));
    console.log('western name: ', await western.name());
    console.log('western symbol: ', await western.symbol());

    /* deploy the RewardRun contract */
    let nestPrice = 10000000000000000000n;
    let rewardsPerMinuteNest = 156250000000000;

    const RewardRun  = await ethers.getContractFactory("RewardRun_V1_0")
    const rewardRun = await RewardRun.deploy(
      westernAddress,
      nestPrice,
      rewardsPerMinuteNest,
      [
        addr2.address,
        addr3.address,
        addr4.address,
      ],
      [
        70, 10, 20
      ]
    )

    await rewardRun.deployed()
    const rewardRunAddress = rewardRun.address
    console.log('rewardRun address: ', rewardRunAddress);
    await rewardRun.createNestWithStake()
    console.log('called createNestWithStake');        // BALANCE TOO LOW
    
  });
});
