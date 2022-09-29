const TokenArkania = artifacts.require("TokenArkania");
const AuctionContract = artifacts.require("AuctionContract");

module.exports = async function (deployer) {
  await deployer.deploy(
    TokenArkania,
    "ARKAN",
    "ARKN",
    "ipfs://QmeSDPcWZ68CUatCzPSw9JJRvrRK11PZGnUK2qMWzkWwMi/"
  );
  let TokenArkaniaInstance = await TokenArkania.deployed();
  console.log(await TokenArkaniaInstance.getAdressDelegateContract());
};
