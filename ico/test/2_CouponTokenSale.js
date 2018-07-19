const CCTCoinSale = artifacts.require("CouponTokenSale.sol");
const CCTCoin = artifacts.require("CouponToken.sol");

 contract("Coupon Token Sale addFounders Test Cases", (accounts) => {
    const owner = accounts[0];

    const fundAddr = accounts[1];
    const contigencyAddr = accounts[2];
    const treassuryAddr = accounts[3];
    
    let token = null;
    let sale = null;
 
    beforeEach("setup contract for each test", async () => {
      token = await CCTCoin.new({from:owner});
      sale = await CCTCoinSale.new(token.address, {from:owner});
      await token.setContractAddresses(sale.address,0,0);
      await sale.setupSale(fundAddr,treassuryAddr,contigencyAddr);
    });


    it("addFounders should not be Owner/Fund/Treasury/Contigency address ",async()=>{
        var founders = [accounts[2],accounts[3],accounts[4]];
        var tokens= [1001,10001,100001];   
    
        try {
          await sale.addFounders(founders,tokens);
          throw(1);
        }catch(err) {
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
         }catch(err) {
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
        }catch(error){
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
    it('once sale begun, owner should not allow to add any Founders',async()=>{
        var founders = [accounts[5],accounts[6],accounts[7]];
        var tokens= [0,110,1110];    
  
        try{
          await sale.setEth2Cents(45000);
          await sale.startSale();
          await sale.addFounders(founders,tokens);
          throw(1);
        }catch(error){
          if(error==1)
          {
              assert(false, 'addFounders successful, add a founder should not allow once sale started.');
           }
        }
    });     
     
    it('only owner should call this function.',async()=>{
        var founders = [accounts[5],accounts[6],accounts[7]];
        var tokens= [10,110,1110];    
         try{
          await sale.addFounders(founders,tokens,{from:accounts[7]});
          throw(1);
          }catch(err) {
            if(err == 1)
              assert(false, 'only owner call this function. validation not handled.');
        }   
    }); 
  
      it("addFounders validation",async()=>{
      var founders = [accounts[5],accounts[6],accounts[7]];
      var tokens= [1001,10001,100001];   
  
      try{
        await sale.addFounders(founders,tokens);
      }catch(err) {
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

    let token = null;
    let sale = null;
  
    beforeEach("setup contract for each test", async () => {
      token = await CCTCoin.new({from: owner });
      sale = await CCTCoinSale.new( token.address, { from: owner });
      await token.setContractAddresses(sale.address,0,0);
      await sale.setupSale(accounts[2],accounts[3],accounts[4]); 
      await sale.setEth2Cents(45000);
      await sale.startSale();    
      //var startSaleFlag = await sale.startSalesFlag();
     // console.log('StartSalesFlag:',startSaleFlag);


    });
  
    it("airDrop should not be greater then 25m ",async()=>{
      var airDroppers = [accounts[5],accounts[6],accounts[7]];
      var tokens=  2500000001 * (10 ** 18); //250 million.


  
      try {
          await sale.airDrop(airDroppers,tokens);
          throw(1);
        }catch(err) {
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
        }catch(err) {
          if(err==1)
            assert(false, 'airDrop successful, Owner/Fund/Treasury/Contigency address validation not handled');
       }   
    });
  
    it('only owner should call this function.',async()=>{
      var airDroppers = [accounts[5],accounts[6],accounts[7]];
      var tokens= 1001;   
  
       try {
        await sale.airDrop(airDroppers,tokens,{from:accounts[5]});
        throw(1);
        }catch(err) {
          if(err==1)
            assert(false, 'only owner call this function. validation not handled.');
        }   
    });   
  
     it('airDrop validation',async()=>{
      var airDroppers = [accounts[5],accounts[6],accounts[7]];
      var tokens= 1000*(10**18); 
    
      try {
        await sale.airDrop(airDroppers,tokens);
        }catch(err) {
          assert(false, 'airDrop Failed.');
      } 
      var x = await sale.remainingAirDropTokens();
      console.log('Airdrop remaining',x.toNumber()/(10**18) );
      //var tokenbalance=await token.balanceOf(accounts[5]);
      //if(tokenbalance != tokens)
      //  assert(false,'airDrop successfully done. But tokens not available into users.')
    });
  });

  contract("Coupon Coin Token buyFiat & calculatePoolBonus Test",(accounts)=>{

    const owner = accounts[0];
    const saleAddr = accounts[1];
    const bountyAddr = accounts[2];
    const compaignAddr = accounts[3];    

    let token = null;
    let sale = null;
  
    beforeEach("setup contract for each test", async () => {
      token = await CCTCoin.new({from: owner });
      sale = await CCTCoinSale.new( token.address, { from: owner });
      await token.setContractAddresses(sale.address,0,0);
      await sale.setupSale(accounts[2],accounts[3],accounts[4]); 
      await sale.setEth2Cents(45000);
      await sale.startSale();
      //var startSaleFlag = await sale.startSalesFlag();
      //console.log('StartSalesFlag:',startSaleFlag);

    });
  
    it('buyFiat validation',async()=>{
      var buyer = accounts[5];
      var cents= 6; 
      try {
        await sale.buyFiat(buyer,cents,{from:owner});
        }catch(err) {
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
        }catch(err) {
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
        }catch(err) {
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

  contract("Coupon Coin Token transfer Test",(accounts)=>{

    const owner = accounts[0];
    const saleAddr = accounts[1];
    const bountyAddr = accounts[2];
    const compaignAddr = accounts[3];     
    
    let token = null;
    let sale = null;
  
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
      await token.setContractAddresses(sale.address,0,0);
      await sale.setupSale(accounts[2],accounts[3],accounts[4]); 
      await sale.setEth2Cents(45000);
      await sale.startSale();
      //var startSaleFlag = await sale.startSalesFlag();
      //console.log('StartSalesFlag:',startSaleFlag);
    });
  
    it('LOT4 users should allow to transfer without any vesting period',async()=>{
      try {
        await sale.buyFiat(buyer1,cents1);
        await sale.buyFiat(buyer2,cents2);
        await sale.buyFiat(buyer3,cents3);
        await sale.buyFiat(buyer4,cents4);
        await sale.endSale();
        await token.transfer(buyer2,1000 *(10**18),{from: buyer4 });
      }catch(err) {
        assert(false, 'users transfer Failed.');
      }   
    });
  
    it("fouders should not allow to transfer until vesting period over.",async()=>{
      var founders = [accounts[5],accounts[6],accounts[7]];
      var tokens= [1001,10001,100001];   
    
      try{
        await sale.addFounders(founders,tokens);
        var tokenbalance=await token.balanceOf(accounts[5]);
        //console.log('Tokens for account no5 :' ,tokenbalance.toNumber());
        if(tokenbalance != tokens[0])
          assert(false,'addFounder successfully done. But tokens not available into users.')    
        await token.transfer(buyer2,1000 *(10**18),{from:accounts[5]});
        throw(1);
        }catch(err)
        {
          if(err == 1)
            assert(false, 'founder transfer success.vesting period validation not handled.');
        }
    });    
  
    it('LOT1/LOT2/LOT3 users should not allow to transfer until vesting period over.',async()=>{
       try {
         await sale.buyFiat(buyer1,cents1);
        await sale.buyFiat(buyer2,cents2);
        await sale.buyFiat(buyer3,cents3);
        await sale.buyFiat(buyer4,cents4);
        await sale.endSale();
        var tknBalanceOf4= await token.balanceOf(buyer2);
        console.log('Buyer 2 Balance Before:',tknBalanceOf4.toNumber()/(10**18));
        await token.transfer(buyer2,1000 *(10**18),{from:buyer1});
        tknBalanceOf4= await token.balanceOf(buyer2);
        console.log('Buyer 2 Balance After:',tknBalanceOf4.toNumber()/(10**18));
        throw(1);
      }catch(err) {
        if(err == 1)
            assert(false, 'users transfer success.vesting period validation not handled.');
      }   
    });  
  });