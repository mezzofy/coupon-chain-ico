const CCTCoin = artifacts.require("CouponToken.sol");
const CCTCoinSale = artifacts.require("CouponTokenSale.sol");

contract("Coupon Coin Token Sale Basic Test", (accounts) => {
  const owner = accounts[0];
  const admin = accounts[1];
  const fund = accounts[2];
  const user = accounts[3];

  let token = null;
  let sale = null;

  beforeEach("setup contract for each test", async () => {
    token = await CCTCoin.new({from: owner });
    sale = await CCTCoinSale.new( token.address, { from: owner }
    );
    await token.setCouponTokenSale(sale.address);
  });

  it("contract owner/admin address should be set corretly", async() => {
    let checkAddr = await token.owner();
    assert.equal(checkAddr, owner);
  }); 

  it("Coupon Token Coin owner should be same with owner", async () => {
    const tokenOwner = await token.owner();
    assert.equal(tokenOwner, owner);
  });

  it("Coupon Token Coin Sale owner should be same with owner", async () => {
    const saleOwner = await sale.owner();
    assert.equal(saleOwner, owner);
  });   

  it("transferEnabled should change after calling enableTransfer/disableTransfer",
    async () => {
    let transferFlag;
    transferFlag = await token.transferEnabled();
    assert.equal(transferFlag, false);

    await token.enableTransfer({ from: owner });
    transferFlag = await token.transferEnabled();
    assert.equal(transferFlag, true);

    await token.disableTransfer({ from: owner });
    transferFlag = await token.transferEnabled();
    assert.equal(transferFlag, false);
  });

  it("only owner can call enableTransfer", async () => {
    try {
      await token.enableTransfer({ from: user });
      assert(false);
    } catch(err) {
      assert(err);
    }

    try {
      await token.enableTransfer({ from: admin });
      assert(false);
    } catch(err) {
      assert(err);
    }
  });
});

contract("Coupon Coin Token Founder Allocation Test", (accounts) => {
  const owner = accounts[0];
  const admin = accounts[1];
  const fund = accounts[2];
  const user = accounts[3];

  let token = null;
  let sale = null

  beforeEach("setup contract for each test", async () => {
    token = await CCTCoin.new({from: owner });
    sale = await CCTCoinSale.new( token.address, { from: owner }
    );
    await token.setCouponTokenSale(sale.address);
    await sale.setupContract(accounts[2],accounts[3],accounts[4]);   
  });

  it("addFounders should not be Owner/Fund/Treasury/Contigency address ",async()=>{
    var founders = [accounts[2],accounts[3],accounts[4]];
    var tokens= [1001,10001,100001];   
     try {
      await sale.addFounders(founders,tokens);
      assert(false, 'addFounders successful, Owner/Fund/Treasury/Contigency address validation not handled');
    } catch(err) {
      assert(true, 'addFounders Failed, test passed ');
    }   
  });  

  it("addFounders should not be greater then 100m ",async()=>{
    var founders = [accounts[5],accounts[6],accounts[7]];
    var tokens= [1001,10001,100000000 * (10 ** 18)];   
     try {
      await sale.addFounders(founders,tokens);
      assert(false, 'addFounders successful, 100m validation not handled');
    } catch(err) {
      assert(true, 'addFounders Failed, test passed ');
    }   
  });  

  
  it("addFounders validation",async()=>{
    var founders = [accounts[5],accounts[6],accounts[7]];
    var tokens= [1001,10001,100001];   

     try {
      await sale.addFounders(founders,tokens);
    } catch(err) {
      assert(false, 'addFounders Failed');
    }   
  });  

  it("next test", async () => {
  });
});
