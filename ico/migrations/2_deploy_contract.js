var CouponToken = artifacts.require("./CouponToken.sol")
var CouponTokenSale = artifacts.require("./CouponTokenSale.sol")
var CouponTokenBounty = artifacts.require("./CouponTokenBounty.sol")
var CouponTokenCampaign = artifacts.require("./CouponTokenCampaign.sol")

module.exports = function(deployer,network,accounts) {
    const owner = accounts[0];

    return deployer.deploy(CouponToken,{ from:owner }
    ).then( ()=> {
        return CouponToken.deployed().then(instance => {
            couponToken = instance;
        })
    }).then( () => {
        return deployer.deploy(CouponTokenSale, couponToken.address, {from:owner}
        ).then( () => {
            return CouponTokenSale.deployed().then(instance => {
                couponTokenSale = instance;
            })
        });        
    }).then( () => {
        return deployer.deploy(CouponTokenBounty, couponToken.address, couponTokenSale.address, {from:owner}
        ).then( () => {
            return CouponTokenBounty.deployed().then(instance => {
                couponTokenBounty = instance;
                couponTokenSale.setBountyAddr(couponTokenBounty.address);
            })
        })
    }).then( () => {
        return deployer.deploy(CouponTokenCampaign, couponToken.address, couponTokenSale.address, {from:owner}
        ).then( () => {
            return CouponTokenCampaign.deployed().then(instance => {
                couponTokenCampaign = instance;
                couponTokenSale.setCampaignAddr(couponTokenCampaign.address);
                
                // Finally setContract Address to CouponToken
                couponToken.setContractAddresses(couponTokenSale.address, couponTokenBounty.address, couponTokenCampaign.address);
            })
        })
    })
}

