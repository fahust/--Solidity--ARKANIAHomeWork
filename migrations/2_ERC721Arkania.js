const TokenArkania = artifacts.require("TokenArkania");
const AuctionContract = artifacts.require("AuctionContract");

module.exports = async function (deployer) {
  await deployer.deploy(TokenArkania, "ARKAN","ARKN","ipfs://QmeSDPcWZ68CUatCzPSw9JJRvrRK11PZGnUK2qMWzkWwMi/");
  let TokenArkaniaInstance = await TokenArkania.deployed();
  console.log(await TokenArkaniaInstance.getAdressDelegateContract());
  /*await deployer.deploy(AuctionContract,TokenArkaniaInstance.address);
  let AuctionContractInstance = await AuctionContract.deployed();
  await TokenArkaniaInstance.setAdressDelegateContract(AuctionContractInstance.address)
  */
  /*for (let index = 0; index < 10; index++) {
    await AuctionContractInstance.mintDelegate();
  }*/
};