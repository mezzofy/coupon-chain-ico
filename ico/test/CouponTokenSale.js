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
 
    it('addFounders token value should not be zero',async()=>{
      var founders = [accounts[5],accounts[6],accounts[7]];
      var tokens= [0,110,1110];    

      try{
        await sale.addFounders(founders,tokens);
        throw(1);
      } catch(error){
        if(error==1)
        {
           var tokenbalance=await token.balanceOf(accounts[5]);
          console.log('Tokens:' ,tokenbalance.toNumber());
          if(tokenbalance.toNumber() <=0)
          {
            assert(false, 'addFounders successful, Token value is zero.Validation not handled');
          }
         }
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
    var tokenbalance=await token.balanceOf(accounts[5]);
    //console.log('Tokens for account no5 :' ,tokenbalance.toNumber());
     if(tokenbalance != tokens[0])
        assert(false,'addFounder successfully done. But tokens not available into users.')    
   });  
});

contract("Coupon Coin Token airDrop Test",(accounts)=>{

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
    await sale.setupContract(accounts[2],accounts[3],accounts[4]); 
    await sale.setEth2Cents(45000);
    await sale.startSale();
  });

  it("airDrop should not be greater then 25m ",async()=>{
    var airDroppers = [accounts[5],accounts[6],accounts[7]];
    var tokens=  2500000000 * (10 ** 18); //250 million.

    try {
        await sale.airDrop(airDroppers,token);
        throw(1);
      } catch(err) {
        if(err==1)
          assert(false, 'airDrop successful, limit not handled');
      }  
  });

  it("airDrop program should not elegible for Owner/Fund/Treasury/Contigency address",async()=>{
    var airDroppers = [accounts[5],accounts[6],accounts[7]];
    var tokens= 1001;   
  
    try {
      await sale.airDrop(airDroppers,token);
       throw(1);
      } catch(err) {
        if(err==1)
          assert(false, 'airDrop successful, Owner/Fund/Treasury/Contigency address validation not handled');
 /*        else
        {
          var tokenbalance=await token.balanceOf(accounts[5]); 
          console.log('airDrop Failed. Tokens reverted to User 5:',tokenbalance.toNumber());
        } */
    }   
  });

  it('airDrop validation',async()=>{
    var airDroppers = [accounts[5],accounts[6],accounts[7]];
    var tokens= 1234; 
  
    try {
      await sale.airDrop(airDroppers,tokens);
      } catch(err) {
          assert(false, 'airDrop Failed.');
    }   

    var tokenbalance=await token.balanceOf(accounts[5]);
    if(tokenbalance != tokens)
      assert(false,'airDrop successfully done. But tokens not available into users.')
  });
});


contract("Coupon Coin Token buyFiat Test",(accounts)=>{

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
    await sale.setupContract(accounts[2],accounts[3],accounts[4]); 
    await sale.setEth2Cents(45000);
    await sale.startSale();
  });


  it('buyFiat validation',async()=>{
    var buyer = accounts[5];
    var cents= 2; 
  
    try {
      await sale.buyFiat(buyer,cents);
      } catch(err) {
          assert(false, 'buyFiat Failed.');
    }   

    //uint256 totalTokens = inCents.div(lotsInfo[currLot].rateInCents) * (10 ** uint256(decimals));
    var tokenbalance=await token.balanceOf(accounts[5]);
    console.log('Tokens:',tokenbalance.toNumber());
    //if(tokenbalance != tokens)
      //assert(false,'airDrop successfully done. But tokens not available into users.')
  });
});
