pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./CouponToken.sol";
import "./CouponTokenSale.sol";


contract CouponTokenBounty {
    using SafeMath for uint256;

    address private owner;

    CouponToken couponToken;
    CouponTokenSale couponTokenSale;

   
    struct EventData {
        string eventName;
        uint256 tokensForEvent;
        bool activated;
        bool killed;
        uint256 tokensIssued;
    }

    // Event Data for Bounty Program
    uint32 bountyIndex;
    mapping(uint32 => EventData) public bountyProgram;


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
    event BountyAction(string actionString, uint32 bountyId);

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
    function createBounty(uint256 noOfTokens, string bountyName)
        external
        onlyOwner
        onlyInSalesState {

        // Condition
        require(noOfTokens > 0 && couponTokenSale.remainingBountyTokens() >= noOfTokens);

        // Generate new event id
        uint32 newEventId = bountyIndex;
        bountyIndex++;

        bountyProgram[newEventId].tokensForEvent = noOfTokens;
        bountyProgram[newEventId].eventName = bountyName;

        emit BountyAction("Bounty Created", newEventId);
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

        emit BountyAction("Bounty Killed", bountyId);
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

        emit BountyAction("Bounty Activated", bountyId);
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
        require(couponTokenSale.IsValidAddress(user));

        // Condition
        require(couponTokenSale.remainingBountyTokens() >= bountyProgram[bountyId].tokensForEvent);

        require(
            bountyId < bountyIndex &&
            bountyProgram[bountyId].activated == true && 
            bountyProgram[bountyId].killed == false);


        uint256 bountyTokens = bountyProgram[bountyId].tokensForEvent;

         // Mint the required tokens
        couponToken.mint(user, bountyTokens);

        // Add it to issuedTokens as well
        bountyProgram[bountyId].tokensIssued = bountyProgram[bountyId].tokensIssued.add(bountyTokens);

        // Set this user as bonus alloted
        couponToken.setBonusUser(user);

        // Subtract it from the Remaining tokens
        couponTokenSale.subtractBountyTokens(bountyTokens);

        // Add tokens to user bonus
        couponTokenSale.addBonusTokens(user, bountyTokens);


        emit BountyAction("Bounty Fullfilled", bountyId);
    }
}