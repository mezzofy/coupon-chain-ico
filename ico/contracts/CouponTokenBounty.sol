pragma solidity ^0.4.20;

import "./CouponToken.sol";
import "./CouponTokenSale.sol";


contract CouponTokenBounty {

    address private owner;

    CouponToken couponToken;
    CouponTokenSale couponTokenSale;

   
    
    struct UserInfoForCampaign {
        bool fullfillmentDone;
        uint256 bonusTokensAlotted;
    }

    struct EventData {
        uint256 tokensForEvent;
        bool activated;
        bool killed;
        mapping (address => UserInfoForCampaign) userInfoForCampaign;
    }

    // Event Data for Bounty Program
    uint32 bountyIndex;
    mapping(uint32 => EventData) bountyProgram;


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
    event BountyAction(bytes32 actionString, uint32 newBountyId);

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
     * Function: createBounty()
     *
    */
    function createBounty(uint256 noOfTokens)
        external
        onlyOwner
        onlyInSalesState {

        // Condition
        require(noOfTokens > 0 && couponTokenSale.remainingBountyTokens() >= noOfTokens);

        // Generate new event id
        uint32 newEventId = bountyIndex;
        bountyIndex++;

        bountyProgram[newEventId].tokensForEvent = noOfTokens;

        emit BountyAction("CREATED", newEventId);
    }

    /*
     *
     * Function: killBounty()
     *
    */
    function killBounty(uint32 bountyId)
        external
        onlyOwner
        onlyInSalesState {
        
        require(
            bountyId < bountyIndex &&
            bountyProgram[bountyId].killed == false);

        bountyProgram[bountyId].killed = true;

        emit BountyAction("KILLED", bountyId);
    }

    /*
     *
     * Function: activateBounty()
     *
    */
    function activateBounty(uint32 bountyId)
        external
        onlyOwner
        onlyInSalesState {

        require(
            bountyId < bountyIndex &&
            bountyProgram[bountyId].activated == false && 
            bountyProgram[bountyId].killed == false);

        bountyProgram[bountyId].activated = true;

        emit BountyAction("ACTIVATED", bountyId);
    }

    


    /*
     *
     * Function: fullfillmentBounty()
     *
    */
    function fullfillmentBounty(uint32 bountyId, address user)
        external 
        onlyOwner
        onlyInSalesState {

        // user should not be empty, founder, owner, treasury, contigency address
        require(
            user != address(0x0) &&
            user != owner &&
            !couponTokenSale.IsPrivateAddress(user) &&
            !couponToken.IsFounder(user));

        // Condition
        require(couponTokenSale.remainingBountyTokens() >= bountyProgram[bountyId].tokensForEvent);

        require(
            bountyId < bountyIndex &&
            bountyProgram[bountyId].activated == true && 
            bountyProgram[bountyId].killed == false);

        // This user should not be fullfilement done already
        require(bountyProgram[bountyId].userInfoForCampaign[user].fullfillmentDone == false);

        uint256 bountyTokens = bountyProgram[bountyId].tokensForEvent;

         // Mint the required tokens
        couponToken.mint(user, bountyTokens);

        // Subtract it from the Remaining tokens
        couponTokenSale.subtractBountyTokens(bountyTokens);

        bountyProgram[bountyId].userInfoForCampaign[user].fullfillmentDone == true;

        emit BountyAction("FULLFILLED", bountyId);
    }
}