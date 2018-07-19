const CCTCoin = artifacts.require("CouponToken.sol");
const CCTCoinSale = artifacts.require("CouponTokenConfig.sol");

contract("Coupon Token Test Cases", (accounts) => {
    const owner = accounts[0];
    const saleAddr = accounts[1];
    const bountyAddr = accounts[2];
    const compaignAddr = accounts[3];
      
    let token = null;
 
    beforeEach("setup contract for each test", async () => {
      token = await CCTCoin.new({ from: owner });
      await token.setContractAddresses(saleAddr,bountyAddr,compaignAddr);
    });

    it("contract owner/admin address should be set corretly", async() => {
      let checkAddr = await token.owner();
      assert.equal(checkAddr, owner);
    }); 
    
    it("Coupon Token Coin owner should be same with contract owner", async () => {
      const tokenOwner = await token.owner();
      assert.equal(tokenOwner, owner);
    });
 
  
/*     it("CouponToken mint should mine the tokens to specified user.",function (done){
      try {
        let user1 = accounts[9];
        let amtTokens=100*(10**18);

        token.mint(user1,amtTokens);

        var mintEvent = token.Mint();
        mintEvent.watch(async function(err, result){
          mintEvent.stopWatching();             
          if(err){
            console.log(err);
            return done(err);
          }
    
          // toAddress = result.args._to;
          //amtToken = result.args._amount;
          //console.log('User emitted tokens:',amtToken); 
          tknBalanceOfUser= await token.balanceOf(user1);
          //console.log('User 1 Balance After emit:',tknBalanceOfUser.toNumber()/(10**18));
          done();
        })        
       }catch(err) {
          assert(false, 'mint Failed');
      }   
    }); */

 
/*     it("CouponToken transfer should transfer the tokens to the destinated user.",async () => {
      try {
        let user1 = accounts[9];
        let amtTokens=100*(10**18);

        await token.transfer(user1,amtTokens);
        tknBalanceOfUser= await token.balanceOf(user1);
        console.log('User 1 Balance:',tknBalanceOfUser.toNumber()/(10**18));
       }catch(err) {
          assert(false, 'transfer failed.');
      }   
    });  */ 

  });