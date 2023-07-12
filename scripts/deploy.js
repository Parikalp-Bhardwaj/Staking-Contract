// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const fs = require("fs")

async function main() {
  [owner] = await ethers.getSigners();
  const Staking = await hre.ethers.getContractFactory("Staking", owner);
  const staking = await Staking.deploy(187848, { value: ethers.utils.parseEther('100') });


  const StakingToken = await ethers.getContractFactory("StakingToken", owner);
  const stakingToken = await StakingToken.deploy()
  const Aed = await hre.ethers.getContractFactory("AEDToken", owner)
  const AedToken = await Aed.deploy()



  await staking.connect(owner).addToken("Staking Token", "STT", stakingToken.address, 800, 1500)
  await staking.connect(owner).addToken("AEDToken", "AEDT", AedToken.address, 900, 1600);
  await staking.deployed();

  console.log(`Staking deployed address ${staking.address}`);
  console.log(`Staking Token deployed address ${stakingToken.address}`);
  console.log(`AED Token deployed address ${AedToken.address}`);



  let addresses = {
    stacking: staking.address,
    StakingToken: stakingToken.address,
    AEDToken: AedToken.address
  }

  let addresJson = JSON.stringify(addresses)

  fs.writeFileSync("./client/src/artifacts/Addresses.json", addresJson)



}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});



