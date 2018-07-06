const CCTCoin = artifacts.require("CouponToken.sol");
const CCTCoinSale = artifacts.require("CouponTokenSale.sol");

contract("CCT Coin Basic Test", (accounts) => {
    const owner = accounts[0];
    const admin = accounts[1];
    const fund = accounts[2];
    const user = accounts[3];
  
    let token = null;
    let sale = null
  
    beforeEach("setup contract for each test", async () => {
      token = await CCTCoin.new({ from: owner });
      sale = await CCTCoinSale.new(
         token.address, { from: owner }
      );
      await token.setCouponTokenSale(sale.address);
    });
  
    it("contract admin address should be set corretly", async() => {
      let checkAddr = await token.owner();
      assert.equal(checkAddr, owner);
    });
  
 
  });