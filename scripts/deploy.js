async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const WesternToken = await ethers.getContractFactory("WESTERN_V1_0");
  const westernToken = await WesternToken.deploy();

  console.log("Western Token address:", westernToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  });
