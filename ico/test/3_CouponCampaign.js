const CCTCoinSale = artifacts.require("CouponTokenSale.sol");
const CCTCoin = artifacts.require("CouponToken.sol");
const CCTCoinCampaign = artifacts.require("CouponTokenCampaign.sol");

contract("Coupon Coin Token createCouponCampaign Test",(accounts)=>{

    const owner = accounts[0];
    
    let token = null;
    let campaign = null;
    let userToken = null;
    let sale = null;
    let userSale = null;
  
    var buyer1 = accounts[6];
    var buyer2 = accounts[7];

  
    var coupons = ['abc','def','ghi'];
    var coupons1 =['abc','jkl','mno'];
  
    beforeEach("setup contract for each test", async () => {
        token = await CCTCoin.new({from: owner });
        sale = await CCTCoinSale.new( token.address, { from: owner });
        campaign = await CCTCoinCampaign.new(token.address,sale.address);
        sale.setCampaignAddr(campaign.address);

        await token.setContractAddresses(sale.address,0,campaign.address);
        await sale.setupSale(accounts[2],accounts[3],accounts[4]); 
        await sale.setEth2Cents(45000);
        await sale.startSale();

        //var startSaleFlag = await sale.startSalesFlag();
        //console.log('StartSalesFlag:',startSaleFlag);

        await campaign.createCouponCampaign(11 *(10**18));
    });
  
  
    it("createCouponCampaign validation",function (done) {
     try {
        campaign.createCouponCampaign(1000 *(10**18));
    
        var compaignCreate = campaign.CouponCampaignAction();      
        compaignCreate.watch(async function(err, result){
        compaignCreate.stopWatching();             
        if(err){
          console.log(err);
          return done(err);
        }
        var newCouponId = result.args.newCouponId;
        //var campaignAction = result.args.actionString;

        //console.log('Campaign Action:',actionString);
        //console.log('Campaign Id:', newCouponId.toNumber());
        await campaign.addCoupon2Campaign(newCouponId,coupons);
        await campaign.activateCouponCampaign(newCouponId);
        await campaign.redeemCoupon(coupons[0],buyer1);
        //await campaign.redeemCoupon(coupons[1],buyer2);
        var tknBalanceOf4= await token.balanceOf(buyer2);
        console.log('User 1 Balance:',tknBalanceOf4.toNumber()/(10**18));
        done();
       })        
       }catch(err) {
        assert(false, 'couponCampaign failed.');
      }   
    });
  
  
    it("*** NOT YET COMPLETED **** coupon redeem works for the given campaign.",function (done) {
      try {
        campaign.createCouponCampaign(1000 *(10**18));
     
         var compaignCreate = campaign.CouponCampaignAction();      
         compaignCreate.watch(async function(err, result){
         compaignCreate.stopWatching();             
         if(err){
           console.log(err);
           return done(err);
         }
         var tknBalanceBefore= await token.balanceOf(buyer1);
         console.log('User 1 Balance:',tknBalanceBefore.toNumber()/(10**18));
  
         var newCouponId = result.args.newCouponId;
         console.log('Campaign Id:', newCouponId.toNumber());
         await campaign.addCoupon2Campaign(newCouponId,coupons);
         await campaign.activateCouponCampaign(newCouponId);
         try{
          await campaign.redeemCoupon(coupons[0],buyer1);
          var tknBalanceAfter= await token.balanceOf(buyer1);
          console.log('User 1 Balance After Redeemed:',tknBalanceAfter.toNumber()/(10**18));        
          if(tknBalanceBefore == tknBalanceAfter)
          {
            throw(1);
          }
         }catch(err)
         {
           if(err==1)
           {
              assert.equal(false,'redeemCoupon not successful, failed to transfer coupons to user.');
           }
         }
         done();  
        })        
        }catch(err){
          assert(false,'couponcampaign error.');
       }  
     });
   
  
    it("coupon id cannot be redeemed twice.",function (done) {
      try {
        campaign.createCouponCampaign(1000 *(10**18));
     
         var campaignCreate = campaign.CouponCampaignAction();      
         campaignCreate.watch(async function(err, result){
         campaignCreate.stopWatching();             
         if(err){
           console.log(err);
           return done(err);
         }
         var newCouponId = result.args.newCouponId;
         await campaign.addCoupon2Campaign(newCouponId,coupons);
         await campaign.activateCouponCampaign(newCouponId);
         await campaign.redeemCoupon(coupons[0],buyer1);
         try{
          await campaign.redeemCoupon(coupons[0],buyer1);
          throw(1);
         }catch(err)
         {
           if(err==1)
            assert(false,'coupon id cannot be redeemed twice.Not Handled.');
         }
         done();
        })        
        }catch(err) {
         assert(false, 'couponCampaign failed.');
       }   
     });
  
     it("before activate coupon, it should not allow to redeem.",function (done) {
      try {
        campaign.createCouponCampaign(1000 *(10**18));
     
         var compaignCreate = campaign.CouponCampaignAction();      
         compaignCreate.watch(async function(err, result){
         compaignCreate.stopWatching();             
         if(err){
           console.log(err);
           return done(err);
         }
        var newCouponId = result.args.newCouponId;
        await campaign.addCoupon2Campaign(newCouponId,coupons);
        try{
         await campaign.redeemCoupon(coupons[0],buyer1);
         throw(1);
        }catch(err)
        {
          if(err == 1)
            assert(false,'before activate coupon, it should not allow to redeem.Not handled.')
        }
  
          done();
        })        
        }catch(err) {
         assert(false, 'couponCampaign failed.');
       }   
     });   
   
     it("after kill couponCampaign, it should not allow to redeem.",function (done) {
      try {
        campaign.createCouponCampaign(1000 *(10**18));
     
         var compaignCreate = campaign.CouponCampaignAction();      
         compaignCreate.watch(async function(err, result){
         compaignCreate.stopWatching();             
         if(err){
           console.log(err);
           return done(err);
         }
        var newCouponId = result.args.newCouponId;
        await campaign.addCoupon2Campaign(newCouponId,coupons);
        await campaign.activateCouponCampaign(newCouponId);
        await campaign.killCouponCampaign(newCouponId);
  
        try{
         await campaign.redeemCoupon(coupons[0],buyer1);
         throw(1);
        }catch(err)
        {
          if(err == 1)
            assert(false,'after kill couponCampaign, it should not allow to redeem.Not handled.')
        }
  
          done();
        })        
        }catch(err) {
         assert(false, 'couponCampaign failed.');
       }   
     });   
  
    it("coupon id should be unique for every campaign.",function (done) {
      try {
         
        campaign.createCouponCampaign(10 *(10**18));
      var compaignCreate = campaign.CouponCampaignAction();      
      compaignCreate.watch(async function(err, result){
        compaignCreate.stopWatching();             
        if(err){
          console.log(err);
          return done(err);
         }
        var compaignId = result.args.newCouponId;
        //console.log('Compaign Id:', compaignId.toNumber());
        await campaign.addCoupon2Campaign(compaignId,coupons);
        
        
        campaign.createCouponCampaign(100 *(10**18));
        var compaignCreate1 = campaign.CouponCampaignAction();      
        compaignCreate1.watch(async function(err1, result1){
        compaignCreate1.stopWatching();             
        if(err1){
          console.log(err1);
          return done(err1);
        }
        var compaignId1 = result1.args.newCouponId;
        //console.log('Compaign Id1:', compaignId1.toNumber());
          try{
            await campaign.addCoupon2Campaign(compaignId1,coupons1);
            throw(1);
          }catch(err)
          {
            if(err==1)
              assert(false,'coupon id should be unique for every campaign.Not Handled.');
          }
        })
      }) 
      done();
     }catch(err) {
       assert(false, 'couponCampaign failed.');
     }   
    });
  
    it("owner/admin/founders not allowed for Coupom campaign.",function (done) {
      try {
        campaign.createCouponCampaign(1000 *(10**18));
     
        var compaignCreate = campaign.CouponCampaignAction();      
        compaignCreate.watch(async function(err, result){
        compaignCreate.stopWatching();             
        if(err){
          console.log(err);
          return done(err);
        }
        var newCouponId = result.args.newCouponId;
        //console.log('Compaign Id:', newCouponId.toNumber());
        await campaign.addCoupon2Campaign(newCouponId,coupons);
        await campaign.activateCouponCampaign(newCouponId);
        try{
         await campaign.redeemCoupon(coupons[0],owner);
         throw(1);
        }catch(err)
        {
          if(err == 1)
           assert(false,'coupon campaign program not allowed for owner/founders. but not handled here.')
        }
        //var tknBalanceOf4= await token.balanceOf(buyer2);
        //console.log('User 1 Balance:',tknBalanceOf4.toNumber()/(10**18));
        done();
        })        
        }catch(err) {
          assert(false, 'couponCampaign failed.');
       }   
     });
   
    it("createCouponCompaign & Id validation",function (done) {
      try {
        campaign.createCouponCampaign(1000 *(10**18));
     
         var compaignCreate = campaign.CouponCampaignAction();      
         compaignCreate.watch(async function(err, result){
          compaignCreate.stopWatching();             
          if(err){
           console.log(err);
           return done(err);
          }
          var newCouponId = result.args.newCouponId;
          //console.log('Compaign Id:', newCouponId.toNumber());
          if(newCouponId == 0)
            assert(false,'CouponId generation is not working properly.')
          done();
        })        
        } catch(err) {
           assert(false, 'couponCampaign failed.');
       }   
     });
   
  
    it("killCouponCampaign validation",function (done) {
      try {
        campaign.createCouponCampaign(1000 *(10**18));
     
        var compaignCreate = campaign.CouponCampaignAction();      
        compaignCreate.watch(async function(err, result){
          compaignCreate.stopWatching();             
          if(err){
            console.log(err);
            return done(err);
          }
          var newCouponId = result.args.newCouponId;
          await campaign.addCoupon2Campaign(newCouponId,coupons);
          await campaign.activateCouponCampaign(newCouponId);
          await campaign.killCouponCampaign(newCouponId);
          try{
            await campaign.activateCouponCampaign(newCouponId);
            throw(1);
            }catch(err)
          {
            if(err == 1)
              assert(false,'activateCouponCampaign succeeded for a invalid coupon id. chk activateCouponCampaign.');
          }       
          done();
          })        
        }catch(err) {
           assert(false, 'couponCampaign failed.');
        }   
     });
   
    it("Coupon campaign should not exceed its maximum tokens.", async () =>  {
      try {
         await campaign.createCouponCampaign(1500000000 *(10**18));
         throw(1);
        }catch(err) {
         if(err == 1)
           assert(false, 'couponCampaign success, maximum tokens not handled properly.');
       }   
     });
  });