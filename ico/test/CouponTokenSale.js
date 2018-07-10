const CCTCoin = artifacts.require("CouponToken.sol");
const CCTCoinSale = artifacts.require("CouponTokenSale.sol");
const truffleAssert = require('truffle-assertions');
 
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

contract("Coupon Coin Token addFounders Test", (accounts) => {
  const owner = accounts[0];
  const admin = accounts[1];
  const fund = accounts[2];
  const user = accounts[3];

  let token = null;
  let sale = null

  beforeEach("setup contract for each test", async () => {
    token = await CCTCoin.new({from: owner });
    sale = await CCTCoinSale.new( token.address, { from: owner });
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
    var tokens=  2500000001 * (10 ** 18); //250 million.

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
     }   
  });

  it('airDrop validation',async()=>{
    var airDroppers = [accounts[5],accounts[6],accounts[7]];
    var tokens= 1000*(10**18); 
  
    try {
      await sale.airDrop(airDroppers,tokens);
      } catch(err) {
          assert(false, 'airDrop Failed.');
    } 
    //var x = await sale.remainingAirDropTokens();
    //console.log('Airdrop remaining',x.toNumber()/(10**18) );
    var tokenbalance=await token.balanceOf(accounts[5]);
    if(tokenbalance != tokens)
      assert(false,'airDrop successfully done. But tokens not available into users.')
  });
});


contract("Coupon Coin Token buyFiat & calculatePoolBonus Test",(accounts)=>{

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

    var tokenbalance=await token.balanceOf(accounts[5]);
    if(tokenbalance == 0)
      assert(false,'buyFiat Failed. But tokens not available into users.')
  });

  it('buyFiat should take unavailable tokens from treasury account if Lot tokens exceeds.',async()=>{
    var buyer1 = accounts[5];
    var buyer2 = accounts[6];
    var buyer3 = accounts[7];

    var cents1= 6 * 15000000; 
    var cents2= 6 * 10000000; 
    var cents3= 6 *  6000000; 

    var TreasuryTotalTokens = 500000000;
    //Lot 1  30000000
  
    try {
      await sale.buyFiat(buyer1,cents1);
      await sale.buyFiat(buyer2,cents2);
      await sale.buyFiat(buyer3,cents3);
      } catch(err) {
          assert(false, 'buyFiat Failed.');
    }   

    var treasuryremaining = await sale.remainingTreasuryTokens();
    if(TreasuryTotalTokens == treasuryremaining)
      assert(false,'buyFiat error.exceeding lot tokens not handled properly.')
  });


  it('buyFiat should allocate poolbonus for lot users',async()=>{
    var buyer1 = accounts[5];
    var buyer2 = accounts[6];
    var buyer3 = accounts[7];

    //30000000
    var cents1= 6 * 15000000; 
    var cents2= 6 * 10000000; 
    var cents3= 6 *  6000000; 

    var poolBonusforLot1 = 3000000;
    var TreasuryTotalTokens = 500000000;
    //Lot 1  30000000
    //Consider bonus for a user is 1000000,if the total user is 3 
  
    try {
      await sale.buyFiat(buyer1,cents1);
      await sale.buyFiat(buyer2,cents2);
      await sale.buyFiat(buyer3,cents3);
      } catch(err) {
          assert(false, 'buyFiat Failed.');
    }   

    var tokenbalance=await token.balanceOf(accounts[5]);
    //console.log('User5 Tokens Before Bonus:',tokenbalance.toNumber()/(10**18))
    
    try{
      await sale.calculatePoolBonus();
    }catch(err){
      assert(false,'calculatePoolBonus Failed.');
    }

    var tokenbalanceAfterPoolBonus=await token.balanceOf(accounts[5]);
    if(tokenbalance == tokenbalanceAfterPoolBonus)
        assert(false,'buyFiat error.calculatePoolBonus not handled properly.')
    //console.log('User5 Tokens After  Bonus:',tokenbalance1.toNumber()/(10**18))
    
  });

});

contract("Coupon Coin Token transfer & transferFrom Test",(accounts)=>{

  const owner = accounts[0];
  
  let token = null;
  let userToken = null;
  let sale = null;
  let userSale = null;

  var buyer1 = accounts[6];
  var buyer2 = accounts[7];
  var buyer3 = accounts[8];
  var buyer4 = accounts[9];

  var cents1= 6 * 30000000; // 30 million
  var cents2= 7 * 60000000; // 60 million
  var cents3= 8 * 90000000; // 90 million
  var cents4= 9 *120000000; // 120 million  

  beforeEach("setup contract for each test", async () => {
    token = await CCTCoin.new({from: owner });
    sale = await CCTCoinSale.new( token.address, { from: owner });
    await token.setCouponTokenSale(sale.address);
    await sale.setupContract(accounts[1],accounts[2],accounts[3]); 
    await sale.setEth2Cents(45000);
    await sale.startSale();    
    
  });

  it('transfer tokens from users test',async()=>{
 
    try {
      
      await sale.buyFiat(buyer1,cents1);
      //var tknBalanceOf4=await token.balanceOf(buyer1);
     // console.log('User 1 Balance:',tknBalanceOf4.toNumber()/(10**18));

      await sale.buyFiat(buyer2,cents2);
      //var tknBalanceOf5=await token.balanceOf(buyer2);
     // console.log('User 2 Balance:',tknBalanceOf5.toNumber()/(10**18));

      await sale.buyFiat(buyer3,cents3);
      //var tknBalanceOf6=await token.balanceOf(buyer3);
      //console.log('User 3 Balance:',tknBalanceOf6.toNumber()/(10**18));

      await sale.buyFiat(buyer4,cents4);
      //var tknBalanceOf7=await token.balanceOf(buyer4);
      //console.log('User 4 Balance:',tknBalanceOf7.toNumber()/(10**18)); 
      
      await sale.endSale();
      //console.log('Sales ended.'); 

      await token.transfer(buyer2,1000 *(10**18),{from: buyer4 });

     // var tknBalanceOf5=await token.balanceOf(buyer2);
     // console.log('User 2 Balance:',tknBalanceOf5.toNumber()/(10**18));

     // var tknBalanceOf7=await token.balanceOf(buyer4);
     // console.log('User 4 Balance:',tknBalanceOf7.toNumber()/(10**18)); 

    } catch(err) {
          assert(false, 'users transfer Failed.');
    }   
  });

  it('**NOT COMPLETE** transfer to founder should not allow before the vesting period complete.',async()=>{
 
    try {
      

/*       var founders = [accounts[2],accounts[3],accounts[4]];
      var tokens= [1001,10001,100001];   
  
      await sale.addFounders(founders,tokens);  */


      await sale.buyFiat(buyer1,cents1);
      //var tknBalanceOf4=await token.balanceOf(buyer1);
      //console.log('User 1 Balance:',tknBalanceOf4.toNumber()/(10**18));

      await sale.buyFiat(buyer2,cents2);
     // var tknBalanceOf5=await token.balanceOf(buyer2);
     // console.log('User 2 Balance:',tknBalanceOf5.toNumber()/(10**18));

      await sale.buyFiat(buyer3,cents3);
      //var tknBalanceOf6=await token.balanceOf(buyer3);
     // console.log('User 3 Balance:',tknBalanceOf6.toNumber()/(10**18));

      await sale.buyFiat(buyer4,cents4);
    //  var tknBalanceOf7=await token.balanceOf(buyer4);
     // console.log('User 4 Balance:',tknBalanceOf7.toNumber()/(10**18)); 
      
      await sale.endSale();
      //console.log('Sales ended.'); 

      await token.transfer(buyer2,1000 *(10**18),{from: buyer4 });

     // var tknBalanceOf5=await token.balanceOf(buyer2);
     // console.log('User 2 Balance:',tknBalanceOf5.toNumber()/(10**18));

     // var tknBalanceOf7=await token.balanceOf(buyer4);
     // console.log('User 4 Balance:',tknBalanceOf7.toNumber()/(10**18)); 

    } catch(err) {
          assert(false, 'users transfer Failed.');
    }   

  });  

});

contract("Coupon Coin Token bounty program Test",(accounts)=>{

  const owner = accounts[0];
  
  let token = null;
  let userToken = null;
  let sale = null;
  let userSale = null;

  var buyer1 = accounts[6];
  var buyer2 = accounts[7];
  var buyer3 = accounts[8];
  var buyer4 = accounts[9];

  var cents1= 6 * 30000000; // 30 million
  var cents2= 7 * 60000000; // 60 million
  var cents3= 8 * 90000000; // 90 million
  var cents4= 9 *120000000; // 120 million  

  var BountyTotalTokens = 15000000;

  beforeEach("setup contract for each test", async () => {
    token = await CCTCoin.new({from: owner });
    sale = await CCTCoinSale.new( token.address, { from: owner });
    await token.setCouponTokenSale(sale.address);
    await sale.setupContract(accounts[1],accounts[2],accounts[3]); 
    await sale.setEth2Cents(45000);
    await sale.startSale();  
    await sale.createBounty(100*(10**18));  
  });


  it("creteBounty/fullfillmentBounty validation",function (done){

    try {
      sale.createBounty(1000*(10**18));
  
      var bountyCreate = sale.BountyCreated();      
      bountyCreate.watch(async function(err, result){
        bountyCreate.stopWatching();             
        if(err){
          console.log(err);
          return done(err);
        }
        await sale.buyFiat(buyer1,cents1);
        await sale.buyFiat(buyer2,cents2);
  
        var newBountyId = result.args.newBountyId;
        //console.log('Bounty Id:', newBountyId.toNumber());
  
        sale.activateBounty(newBountyId)
        //console.log('Activated Bounty Id: ',newBountyId.toNumber());

        var bountyremaining = await sale.remainingBountyTokens();
        if(BountyTotalTokens == bountyremaining)
          assert(false,'Bounty Program error.Bounty token balance handled properly.');
    
        sale.fullfillmentBounty(newBountyId,buyer1);
        sale.fullfillmentBounty(newBountyId,buyer2);

        //tknBalanceOf4= await token.balanceOf(buyer1);
        //console.log('User 1 Balance:',tknBalanceOf4.toNumber()/(10**18));
        //tknBalanceOf5=await token.balanceOf(buyer2);
        //console.log('User 2 Balance:',tknBalanceOf5.toNumber()/(10**18));
        done();
     })        
     
     } catch(err) {
      assert(false, 'createBounty Failed');
    }   
  });

  it("creteBounty should not exceed the Bounty Maximum Limit",async () => {

    try {
      await sale.createBounty(150000001*(10**18));
      throw(1);

     } catch(err) {
       if(err == 1)
          assert(false, 'createBounty successful.Max limit not handled.');
    }   
  });  

  it("createBounty bountyID validation",function (done) {

    try {
      sale.createBounty(1000*(10**18));
  
      var bountyCreate = sale.BountyCreated();      
      bountyCreate.watch(async function(err, result){
        bountyCreate.stopWatching();             
        if(err){
          console.log(err);
          return done(err);
        }
 
        var newBountyId = result.args.newBountyId;
        //console.log('Bounty Id:', newBountyId.toNumber());
        if(newBountyId == 0)
        {
          err = 1;
          return done(err);
        }
        done();
     })        
     } catch(err) {
       if(err == 1)
        assert(false, 'createBounty success, bountyId not handled properly.');
    }   
  });
});

contract("Coupon Coin Token createCouponCampaign Test",(accounts)=>{

  const owner = accounts[0];
  
  let token = null;
  let userToken = null;
  let sale = null;
  let userSale = null;

  var buyer1 = accounts[6];
  var buyer2 = accounts[7];
  var buyer3 = accounts[8];
  var buyer4 = accounts[9];

  var cents1= 6 * 30000000; // 30 million
  var cents2= 7 * 60000000; // 60 million
  var cents3= 8 * 90000000; // 90 million
  var cents4= 9 *120000000; // 120 million  

  var CouponCampaignTotalTokens = 15000000;
  var coupons = ['abc1','abc2','abc3'];

  beforeEach("setup contract for each test", async () => {
    token = await CCTCoin.new({from: owner });
    sale = await CCTCoinSale.new( token.address, { from: owner });
    await token.setCouponTokenSale(sale.address);
    await sale.setupContract(accounts[1],accounts[2],accounts[3]); 
    await sale.setEth2Cents(45000);
    await sale.startSale();  
    await sale.createCouponCompaign(1000 *(10**18));
  });


  it("createCouponCompaign validation",function (done) {
   try {
      sale.createCouponCompaign(1000 *(10**18));
  
      var compaignCreate = sale.CouponCampaignCreated();      
      compaignCreate.watch(async function(err, result){
      compaignCreate.stopWatching();             
      if(err){
        console.log(err);
        return done(err);
      }
      var newEventId = result.args.newEventId;
      //console.log('Compaign Id:', newEventId.toNumber());

      await sale.addCoupon2Compaign(newEventId,coupons)
      await sale.activateCouponCompaign(newEventId);
      await sale.redeemCoupon(coupons[0],buyer1);
      await sale.redeemCoupon(coupons[0],buyer2);
      //var tknBalanceOf4= await token.balanceOf(buyer2);
      //console.log('User 1 Balance:',tknBalanceOf4.toNumber()/(10**18));

      done();
     })        
     } catch(err) {
        assert(false, 'couponCompaign failed.');
    }   
  });

  it("Coupon compaign should not exceed its maximum tokens.", async () =>  {
    try {
       await sale.createCouponCompaign(1500000000 *(10**18));
       throw(1);
   
      } catch(err) {
       if(err == 1)
         assert(false, 'couponCompaign success, maximum tokens not handled properly.');
     }   
   });
});