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

  it("Coupon Token Coin owner should be same with contract owner", async () => {
    const tokenOwner = await token.owner();
    assert.equal(tokenOwner, owner);
  });

  it("Coupon Token Coin Sale owner should be same with contract owner", async () => {
    const saleOwner = await sale.owner();
    assert.equal(saleOwner, owner);
  });   
});

contract("Coupon Coin Token Start Sale Test", (accounts) => {

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

  it("Start sale should have eth rate.",async()=>{
    try {
      await sale.startSale();
      throw(1);
    } catch(err) {
      if(err==1)
        assert(false, 'startSale successful, Eth to Cents conversion not handled');
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
      throw(1);
    } catch(err) {
      if(err==1)
        assert(false, 'addFounders successful, Owner/Fund/Treasury/Contigency address validation not handled');
    }   
  });

  it("addFounders should not be greater then 100m ",async()=>{
    var founders = [accounts[5],accounts[6],accounts[7]];
      var tokens= [1001,10001,100000000*(10 ** 18)];   

      try {
        await sale.addFounders(founders,tokens);
        throw(1);
      } catch(err) {
        if(err==1)
          assert(false, 'addFounders successful, Founder limit not handled');
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
});


