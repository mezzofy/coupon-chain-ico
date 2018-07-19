const CCTCoinSale = artifacts.require("CouponTokenSale.sol");
const CCTCoin = artifacts.require("CouponToken.sol");
const CCTBounty =artifacts.require("CouponTokenBounty.sol");

contract("Coupon Coin Token bounty program Test",(accounts)=>{

    const owner = accounts[0];
    
    let token = null;
    let sale = null;
    let bounty = null;
    
  
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
        
        bounty = await CCTBounty.new(token.address,sale.address);
        sale.setBountyAddr(bounty.address);

        await token.setContractAddresses(sale.address,bounty.address,0);
        await sale.setupSale(accounts[2],accounts[3],accounts[4]); 
        await sale.setEth2Cents(45000);
        await sale.startSale();

        //var startSaleFlag = await sale.startSalesFlag();
        //console.log('StartSalesFlag:',startSaleFlag);      
        await bounty.createBounty(100*(10**18));  
    });
  
    it("createBounty/fullfillmentBounty validation",function (done){
      try {
        bounty.createBounty(1000*(10**18));
        var bountyCreate = bounty.BountyAction();      
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
          await bounty.activateBounty(newBountyId)
          //console.log('Activated Bounty Id: ',newBountyId.toNumber());
          var bountyremaining = await sale.remainingBountyTokens();
          if(BountyTotalTokens == bountyremaining)
            assert(false,'Bounty Program error.Bounty token balance handled properly.');
          bounty.fullfillmentBounty(newBountyId,buyer1);
          bounty.fullfillmentBounty(newBountyId,buyer2);
          //tknBalanceOf4= await token.balanceOf(buyer1);
          //console.log('User 1 Balance:',tknBalanceOf4.toNumber()/(10**18));
          //tknBalanceOf5=await token.balanceOf(buyer2);
          //console.log('User 2 Balance:',tknBalanceOf5.toNumber()/(10**18));
          done();
        })        
       }catch(err) {
          assert(false, 'createBounty Failed');
      }   
    });
  
    it("owner/admin/founders should not allow for bounty program.",function (done){
      try {
        bounty.createBounty(1000*(10**18));
    
        var bountyCreate = bounty.BountyAction();      
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
          bounty.activateBounty(newBountyId)
          //console.log('Activated Bounty Id: ',newBountyId.toNumber());
          var bountyremaining = await sale.remainingBountyTokens();
          if(BountyTotalTokens == bountyremaining)
            assert(false,'Bounty Program error.Bounty token balance handled properly.');
      
          try
          {
            await bounty.fullfillmentBounty(newBountyId,owner);
            throw(1);
          }
          catch(err)
          {
            if(err == 1)
              assert(false,'owner should not allow to participate bounty program.')
          }
          done();
       })        
      }catch(err) {
        assert(false, 'createBounty Failed');
      }   
    });
  
    it("creteBounty should not exceed the Bounty Maximum Limit",async () => {
      try {
        await bounty.createBounty(150000001*(10**18));
        throw(1);
       }catch(err) {
          if(err == 1)
            assert(false, 'createBounty successful.Max limit not handled.');
      }   
    });  
  
    it("killBounty validation",function (done) {
      var newBountyId;
      try {
        bounty.createBounty(1000*(10**18));
        var bountyCreate = bounty.BountyAction();      
        bountyCreate.watch(async function(err, result){
          bountyCreate.stopWatching();             
          if(err){
            console.log(err);
            return done(err);
          }
          newBountyId = result.args.newBountyId;
          await bounty.activateBounty(newBountyId)
          oldBountyId = newBountyId;
          await bounty.killBounty(newBountyId);
          try{
            await bounty.activateBounty(newBountyId);
            throw(1);
          }catch(err)
          {
            if(err == 1)
              assert(false,'activateBounty succeeded for a invalid bounty id. chk killbounty.');
          }
          done();
       })        
       }catch(err) {
          assert(false, 'killBounty Failed.');
      }       
    });  
  
    it("createBounty bountyID validation",function (done) {
      try {
        bounty.createBounty(1000*(10**18));
    
        var bountyCreate = bounty.BountyAction();      
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
       }catch(err) {
        if(err == 1)
          assert(false, 'createBounty success, bountyId not handled properly.');
      }   
    });
  });