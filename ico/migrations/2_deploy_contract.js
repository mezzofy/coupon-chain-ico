var CouponToken = artifacts.require("./CouponToken.sol")
var CouponTokenSale = artifacts.require("./CouponTokenSale.sol")

module.exports = function(deployer,network,accounts) {
    const owner = accounts[0];
    //const fundAddr = accounts[1];

    return deployer.deploy(
        CouponToken,{ from:owner }
    ).then( ()=> {
        return CouponToken.deployed().then(instance => {
            couponToken = instance;
        })
    }).then( () => {
        return deployer.deploy(
            CouponTokenSale, /*fundAddr,*/ couponToken.address, {from:owner}
        ).then( () => {
            return CouponTokenSale.deployed().then(instance => {
                couponTokenSale = instance;
                couponToken.setCouponTokenSale(couponTokenSale.address);
            })
        });        
    });
}

/*
module.exports = async (deployer, network, accounts) => {
    const owner = accounts[0];
    const fundAddr = accounts[1];
  
    await deployer.deploy(CouponToken,{ from: owner });
    const couponToken = await CouponToken.deployed();
  
    await deployer.deploy(CouponTokenSale, fundAddr, couponToken.address, { from: owner });
    const couponTokenSale = await CouponTokenSale.deployed();
    
    await couponToken.setTokenSaleAmount(couponTokenSale.address, 0);
};
*/