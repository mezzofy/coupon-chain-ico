pragma solidity ^0.4.21;


import "./CouponToken.sol";
import "./CouponTokenSale.sol";

contract CouponTokenCampaign {
    
    address private owner;

    CouponToken couponToken;
    CouponTokenSale couponTokenSale;

   
    struct UserInfoForCampaign {
        bool fullfillmentDone;
        uint256 bonusTokensAlotted;
    }

    struct EventData {
        string eventName;
        uint256 tokensForEvent;
        bool activated;
        bool killed;
        uint32 noOfCouponsAdded; 
        mapping (address => UserInfoForCampaign) userInfoForCampaign;
    }

    struct CouponCampaignInfo {
        uint32 campaignId;
        bool added;
        bool redeemed;
    }
   

    // Event-data for Coupon Bonus Program
    uint32 couponCampaignIndex;
    mapping(uint32 => EventData) public couponCampaignProgram;

    // Coupons mapping
    mapping(bytes32 => CouponCampaignInfo) public couponInfo;


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyInSalesState() {
        require(couponTokenSale.startSalesFlag() == true && couponTokenSale.endSalesFlag() == false);
        _;
    }

    /*
     * Events
     */
    event CouponCampaignAction(string actionString, uint32 campaignId);


    /*
     * Constructor
     */
    constructor(address _couponToken, address _couponTokenSale) public {
        owner = msg.sender;
        couponToken = CouponToken(_couponToken);
        couponTokenSale = CouponTokenSale(_couponTokenSale);
    }


    /*
     *
     * Function: createCoupon()
     *
     */
    function createCouponCampaign(uint256 noOfTokens, string campaignName)
        external
        onlyOwner
        onlyInSalesState 
        returns (uint32) {

        // Condition
        require(couponTokenSale.remainingCouponTokens() >= noOfTokens);

        // Generate new event id
        uint32 newCouponId = couponCampaignIndex;
        couponCampaignIndex++;

        couponCampaignProgram[newCouponId].tokensForEvent = noOfTokens;
        couponCampaignProgram[newCouponId].eventName = campaignName;

        emit CouponCampaignAction("Campaign Created", newCouponId);
    }
    
     /*
     *
     * Function: killCoupon()
     *
    */
    function killCouponCampaign(uint32 campaignId)
        external
        onlyOwner
        onlyInSalesState
        returns (uint32) {
        
        require(
            campaignId < couponCampaignIndex && 
            couponCampaignProgram[campaignId].killed == false);

        couponCampaignProgram[campaignId].killed = true;

        emit CouponCampaignAction("Campaign Killed", campaignId);

    }

    /*
     *
     * Function: addCoupon2Campaign()
     *
     */
    function addCoupon2Campaign(uint32 campaignId, bytes32[] coupons) 
        external
        onlyOwner
        onlyInSalesState {

        require(
            campaignId < couponCampaignIndex && 
            coupons.length > 0 &&
            couponCampaignProgram[campaignId].activated == false && 
            couponCampaignProgram[campaignId].killed == false);

        
        // Check for duplicate coupons
        for(uint32 i = 0; i < coupons.length; i++) {
            require(coupons[i] != 0x0);
            require(couponInfo[coupons[i]].added == false);
        }

        // Add the coupons
        for(i = 0; i < coupons.length; i++) {
            couponInfo[coupons[i]].campaignId = campaignId;
            couponInfo[coupons[i]].added = true;
        }

        // Set no.of coupons
        couponCampaignProgram[campaignId].noOfCouponsAdded = 
            couponCampaignProgram[campaignId].noOfCouponsAdded + uint32(coupons.length);

        emit CouponCampaignAction("Coupons Added in Campaign", campaignId);

    }

    /*
     *
     * Function: activateCouponCampaign()
     *
     */
    function activateCouponCampaign(uint32 campaignId)
        external
        onlyOwner
        onlyInSalesState {

        require(
            campaignId < couponCampaignIndex && 
            couponCampaignProgram[campaignId].activated == false && 
            couponCampaignProgram[campaignId].killed == false);

        couponCampaignProgram[campaignId].activated = true;

        emit CouponCampaignAction("Campaign Activated", campaignId);
    }

    

    /*
     *
     * Function: redeemCoupon()
     *
    */
    function redeemCoupon(bytes32 coupon, address user)
        external 
        onlyOwner
        onlyInSalesState {

        // user should not be empty, founder, owner, treasury, contigency address
        require(couponTokenSale.IsValidAddress(user));

        // Coupon should be added already and not redeemed
        require(couponInfo[coupon].added == true && couponInfo[coupon].redeemed == false);

        // Sufficient tokens available?
        uint32 campaignId = couponInfo[coupon].campaignId;
        require(couponTokenSale.remainingBountyTokens() >= couponCampaignProgram[campaignId].tokensForEvent);

        require(
            campaignId < couponCampaignIndex &&
            couponCampaignProgram[campaignId].activated == true && 
            couponCampaignProgram[campaignId].killed == false);

        // This user should be participated already and fullfilement not done
        require(couponCampaignProgram[campaignId].userInfoForCampaign[user].fullfillmentDone == false);

        uint256 campaignTokens = couponCampaignProgram[campaignId].tokensForEvent;

        // Mint the required tokens
        couponToken.mint(user, campaignTokens);
        // Set this user as bonus alloted
        couponToken.setBonusUser(user);

        // Subtract it from the Remaining tokens
        couponTokenSale.subtractCampaignTokens(campaignTokens);

        // Add tokens to user bonus
        couponTokenSale.addBounusTokens(user, campaignTokens);
        
        // Mark this coupon as redeemed
        couponInfo[coupon].redeemed = true;
        
        couponCampaignProgram[campaignId].userInfoForCampaign[user].fullfillmentDone == true;

        emit CouponCampaignAction("Coupon Redeemed in Campaign", campaignId);
    }
}