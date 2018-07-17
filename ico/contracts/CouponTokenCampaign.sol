pragma solidity ^0.4.20;


import "./CouponToken.sol";
import "./CouponTokenSale.sol";

contract CouponTokenCampaign {
    
    address private owner;

    CouponToken couponToken;
    CouponTokenSale couponTokenSale;

    bool public inSaleState;

    struct UserInfoForCampaign {
        bool fullfillmentDone;
        uint256 bonusTokensAlotted;
    }

    struct EventData {
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
    mapping(uint32 => EventData) couponCampaignProgram;

    // Coupons mapping
    mapping(bytes32 => CouponCampaignInfo) couponInfo;


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
    event CouponCampaignAction(bytes32 actionString, uint32 newCouponId);


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
    function createCouponCampaign(uint256 noOfTokens)
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

        emit CouponCampaignAction("CREATED", newCouponId);
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

        emit CouponCampaignAction("KILLED", campaignId);

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
            coupons.length > 0);

        // Check for duplicate coupons
        for(uint32 i = 0; i < coupons.length; i++) {
            require(couponInfo[coupons[i]].added == false);
        }

        // Add the coupons
        for(i = 0; i < coupons.length; i++) {
            couponInfo[coupons[i]].campaignId = campaignId;
            couponInfo[coupons[i]].added = true;
        }

        // Set no.of coupons
        couponCampaignProgram[campaignId].noOfCouponsAdded = uint32(coupons.length);

        emit CouponCampaignAction("ADDCOUPON", campaignId);

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

        emit CouponCampaignAction("ACTIVATED", campaignId);
    }

    

    /*
     *
     * Function: redeemCoupon()
     *
    */
    function redeemCoupon(bytes32 couponId, address user)
        external 
        onlyOwner
        onlyInSalesState {

        // user should not be empty, founder, owner, treasury, contigency address
        require(
            user != address(0x0) &&
            user != owner &&
            !couponTokenSale.IsPrivateAddress(user) &&
            !couponToken.IsFounder(user));

        // Coupon should be added already and not redeemed
        require(couponInfo[couponId].added == true && couponInfo[couponId].redeemed == false);

        // Sufficient tokens available?
        uint32 campaignId = couponInfo[couponId].campaignId;
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
        couponToken.setUserwhoGotBonus(user, campaignTokens);

        // Subtract it from the Remaining tokens
        couponTokenSale.subtractCampaignTokens(campaignTokens);
        

        // Mark this coupon as redeemed
        couponInfo[couponId].redeemed = true;
        
        couponCampaignProgram[campaignId].userInfoForCampaign[user].fullfillmentDone == true;

        emit CouponCampaignAction("REDEEMED", campaignId);
    }

}