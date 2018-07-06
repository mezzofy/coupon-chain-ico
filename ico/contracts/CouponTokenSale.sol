pragma solidity ^0.4.20;

import "./CouponToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract CouponTokenSale is Pausable {
    using SafeMath for uint256;

    // Start time of Sale
    uint256 public startSaleTime;

    // Start time of the Sale-lot 4
    uint256 public startTimeOfSaleLot4;

    // End time of Sale
    uint256 public endSaleTime;

    // Flag to mark endSales
    bool private endSalesFlag;


    uint256 private rateEth2Cents;

    // Address to collect fund
    address private fundAddr;
    
    // Address for treasury
    address private treasuryAddr;

    // Address of Contigency
    address private contigencyAddr;

    // Coupon Token contract address
    CouponToken public couponToken;

    // Amount of raised in Wei (1 ether)
    uint256 public totalWeiRaised;

    // TreasuryTokens
    uint256 public remainingTreasuryTokens;

    // Compaigns Tokens
    uint256 public remainingAirDropTokens;
    uint256 public remainingBountyTokens;
    uint256 public remainingCouponTokens;
    uint256 public remainingReferralTokens;

    /*
     *
     * C O N S T A N T S
     *
    */
    uint8 public constant decimals = 18;

    // Total coupon supply, 1 billion
    uint256 public constant TOTAL_COUPON_SUPPLY = 1000000000 * (10 ** uint256(decimals)); // 1 billion
    
    // Coupon Sale Allowance for Crowd Sales, 300 million
    uint256 public constant TOKEN_SALE_ALLOWANCE =  300000000 * (10 ** uint256(decimals)); // 300 million
    
    // Maximum CAP for founders, 100 million
    uint256 public constant MAX_CAP_FOR_FOUNDERS = 100000000 * (10 ** uint256(decimals)); // 100 million

    // Maximum CAP for treasury, 500 million
    uint256 public constant MAX_CAP_FOR_TREASURY = 500000000 * (10 ** uint256(decimals)); // 500 million

    // Maximum CAP for contigency, 100 million
    uint256 public constant MAX_CAP_FOR_CONTIGENCY = 100000000 * (10 ** uint256(decimals)); // 100 million

    // Total token Sales 300 million, which will be sold in 4 lots, as like below
    // Maximum CAP for each lot sales 
    uint256 constant MAX_CAP_FOR_LOT1 =  30000000 * (10 ** uint256(decimals)); // 30 million
    uint256 constant MAX_CAP_FOR_LOT2 =  60000000 * (10 ** uint256(decimals)); // 60 million
    uint256 constant MAX_CAP_FOR_LOT3 =  90000000 * (10 ** uint256(decimals)); // 90 million
    uint256 constant MAX_CAP_FOR_LOT4 = 120000000 * (10 ** uint256(decimals)); // 120 million

    uint256 constant RATE_FOR_LOT1 = 6;  // USD $0.06 Cents
    uint256 constant RATE_FOR_LOT2 = 7;  // USD $0.07 Cents
    uint256 constant RATE_FOR_LOT3 = 8;  // USD $0.08 Cents
    uint256 constant RATE_FOR_LOT4 = 9;  // USD $0.09 Cents

    // Total Pool Bonus 30 million
    uint256 constant POOL_BONUS_LOT1 =  3000000 * (10 ** uint256(decimals)); // 3 million
    uint256 constant POOL_BONUS_LOT2 =  6000000 * (10 ** uint256(decimals)); // 6 million
    uint256 constant POOL_BONUS_LOT3 =  9000000 * (10 ** uint256(decimals)); // 9 million
    uint256 constant POOL_BONUS_LOT4 = 12000000 * (10 ** uint256(decimals)); // 12 million

    // Constants for lot sales related
    uint8 constant public MAX_SALE_LOTS = 4;
    uint8 constant public SALE_LOT1 = 0;
    uint8 constant public SALE_LOT2 = 1;
    uint8 constant public SALE_LOT3 = 2;
    uint8 constant public SALE_LOT4 = 3;

    uint256 constant POOL_BONUS_ELIGIBLE = 50000 * (10 ** uint256(decimals)); // 50 thousand

    // Max.Cap for Campaigns, which are all taken from Treasury
    uint256 constant MAX_CAP_AIRDROP_PROGRAM = 25000000 * (10 ** uint256(decimals)); // 25 million
    uint256 constant MAX_CAP_BOUNTY_PROGRAM =  15000000 * (10 ** uint256(decimals)); // 15 million
    uint256 constant MAX_CAP_REFERRAL_PROGRAM =  15000000 * (10 ** uint256(decimals)); // 15 million
    uint256 constant MAX_CAP_COUPON_PROGRAM =  15000000 * (10 ** uint256(decimals)); // 15 million
        
    // There are three stages
    enum Stages {
        Setup,
        Started,
        Ended
    }

    // Current Stage for the Sale
    Stages public stage;

    
    // The current lot of the sale(1, 2, 3, 4)
    uint8 public currLot;

    struct BuyerInfoForPoolBonus {
        uint256 noOfTokensBought;
        bool bonusEligible;
        uint256 bonusTokensAlotted;
    }

    // Information related to lots
    struct LotInfos {
        uint256 totalTokens;
        uint256 rateInCents;
        uint256 poolBonus;
        uint256 soldTokens;
        uint256 totalCentsRaised;
        mapping(address => BuyerInfoForPoolBonus) buyerInfoForPoolBonus;
        address[] buyersList;
        uint256 cumulativeBonusTokens;
        bool poolBonusCalculated;
    }

    struct UserInfoForCampaign {
        bool participated;
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
    EventData[] public bountyProgram;

    // Event-data for Coupon Bonus Program
    EventData[] public couponProgram;

    // Mappings for Referrals
    mapping(address => address) referrals;

    // List of Lots information
    mapping(uint8 => LotInfos) public lotsInfo;


     // List for Founders
    mapping(address => uint256) public founders;

    /*
     * Events
     */
      /*
     * Event for sale start logging
     *
     * @param startTime: Start date of sale
     * @param endTime: End date of sale
     *
     */
    event SaleStarted(uint256 startTime);

    /*
     * Event for token purchase
     *
     * @param purchaser: Who paid for the tokens
     * @param value: Amount in Wei paid for purchase
     * @param amount: Amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    /*
     * Modifiers
     */
    modifier atStage(Stages expectedStage) {
        require(expectedStage == stage);
        _;
    }

    modifier onlyValidPurchase() {
        require(now >= startSaleTime);

        address purchaser = msg.sender;

        require(purchaser != address(0));

        _;
    }

    /*
     * Constructor
     */
    constructor(address couponTokenAddress) public {
        
        require(couponTokenAddress != address(0));

        // Get the address of couponToken and store it
        couponToken = CouponToken(couponTokenAddress);

        // Initially set the state as Ended
        stage = Stages.Ended;

        // Fill Lots Information to structure
        lotsInfo[SALE_LOT1].totalTokens = MAX_CAP_FOR_LOT1;
        lotsInfo[SALE_LOT1].rateInCents = RATE_FOR_LOT1;
        lotsInfo[SALE_LOT1].poolBonus = POOL_BONUS_LOT1;

        lotsInfo[SALE_LOT2].totalTokens = MAX_CAP_FOR_LOT2;
        lotsInfo[SALE_LOT2].rateInCents = RATE_FOR_LOT2;
        lotsInfo[SALE_LOT2].poolBonus = POOL_BONUS_LOT2;

        lotsInfo[SALE_LOT3].totalTokens = MAX_CAP_FOR_LOT3;
        lotsInfo[SALE_LOT3].rateInCents = RATE_FOR_LOT3;
        lotsInfo[SALE_LOT3].poolBonus = POOL_BONUS_LOT3;

        lotsInfo[SALE_LOT4].totalTokens = MAX_CAP_FOR_LOT4;
        lotsInfo[SALE_LOT4].rateInCents = RATE_FOR_LOT4;
        lotsInfo[SALE_LOT4].poolBonus = POOL_BONUS_LOT4;

        // Initialize
        remainingTreasuryTokens = MAX_CAP_FOR_TREASURY;

        // Initialize Campaign bonus values
        remainingAirDropTokens = MAX_CAP_AIRDROP_PROGRAM;
        remainingBountyTokens = MAX_CAP_BOUNTY_PROGRAM;
        remainingCouponTokens = MAX_CAP_COUPON_PROGRAM;
        remainingReferralTokens = MAX_CAP_REFERRAL_PROGRAM;

    }

    /*
     * Fallback function to buy CCT tokens
     */
    function () public payable {
        buy();
    }

    /*
     * Withdraw ethers to fund address
     */
    function withdraw() external onlyOwner {
        fundAddr.transfer(address(this).balance);
    }

    /*
     * SetupContract with addresses
     */
    function setupContract(address _fundAddr, address _treasuryAddr, address _contigencyAddr) 
        external
        onlyOwner
        atStage(Stages.Ended) {

        require(_fundAddr != address(0));
        require(_treasuryAddr != address(0));
        require(_contigencyAddr != address(0));

        
        // Assign address
        fundAddr = _fundAddr;
        treasuryAddr = _treasuryAddr;
        contigencyAddr = _contigencyAddr;

        // Change the Stage as Setup
        stage = Stages.Setup;

    }

      /*
     * Allocation to Founders
     *
     */
    function addFounders(address[] Users, uint256[] Tokens)
        public 
        onlyOwner 
        atStage(Stages.Setup) {

        // Both array length should be same
        require(Users.length > 0 && Users.length == Tokens.length);

        // Check the total amount should not cross the MAX_CAP_FOR_FOUNDERS
        uint256 totalFounderAllocation = 0;
        for(uint i = 0; i < Tokens.length; i++) { 
            totalFounderAllocation = totalFounderAllocation.add(Tokens[i]);

            // Founders address should validate following
            require(Users[i] != address(0) && Users[i] != fundAddr && Users[i] != treasuryAddr && Users[i] != contigencyAddr && Tokens[i] > 0);
        }
        
        // Total tokens should be more than CAP
        require(totalFounderAllocation <= MAX_CAP_FOR_FOUNDERS);
        
        // Allocation for founders 
        for(i = 0; i < Users.length; i++) { 
            // Assign tokens
            founders[Users[i]] = Tokens[i];

            // Mint the required tokens
            couponToken.mint(Users[i], Tokens[i]);
        }
    }


    /*
     *
     *
    */
    function setEth2Cents(uint256 rate) 
        public
        onlyOwner {

        rateEth2Cents = rate;

    }

    /*
     * Start sale
     */
    function startSale()
        external
        onlyOwner
        atStage(Stages.Setup)
    {
        require(rateEth2Cents >= 0);
        
        stage = Stages.Started;
        currLot = SALE_LOT1;
        startSaleTime = now;

        // Fire the event
        emit SaleStarted(startSaleTime);
    }

     /*
     * End sale
     */
    function endSale() 
        external
        onlyOwner {

        // Flag to prevent the second call of this function
        require(endSalesFlag == false);

        // Allocate tokens for contigency
        couponToken.mint(contigencyAddr, MAX_CAP_FOR_CONTIGENCY);

        // Calculate remaing balance for Treasury
        uint256 treasuryTokens = remainingTreasuryTokens - 
            (POOL_BONUS_LOT1 + POOL_BONUS_LOT2 + POOL_BONUS_LOT3 + POOL_BONUS_LOT4) -
            (MAX_CAP_AIRDROP_PROGRAM - remainingAirDropTokens) - 
            (MAX_CAP_BOUNTY_PROGRAM - remainingBountyTokens) -
            (MAX_CAP_REFERRAL_PROGRAM - remainingReferralTokens) -
            (MAX_CAP_COUPON_PROGRAM - remainingCouponTokens);

        // mint the balance to Treasury wallet
        couponToken.mint(treasuryAddr, treasuryTokens);

        // Check if sale already end by purchase
        if(stage == Stages.Started) {
            endSaleTime = now;
            stage = Stages.Ended;
        }

        endSalesFlag = true;
    }

    /*
     * Function: buy()
     */
    function buy()
        public 
        payable
        whenNotPaused
        atStage(Stages.Started)
        onlyValidPurchase()
        returns (bool) {

        address purchaser = msg.sender;
        uint256 contributionInWei = msg.value;
        uint256 contributioninEth = contributionInWei.div(10 ** uint256(decimals));
        uint256 inCents = contributioninEth.mul(rateEth2Cents);

        uint256 totalTokens = purchase(purchaser, inCents);

        // Transfer contributions to fund address
        fundAddr.transfer(contributionInWei);
        emit TokenPurchase(msg.sender, contributionInWei, totalTokens);

        return true;
    }

    function buyFiat(address toUser, uint256 inCents) 
        public
        onlyOwner
        whenNotPaused
        atStage(Stages.Started)
        returns (bool) {

        // Call purchase()    
        purchase(toUser, inCents);

        return true;
    }

    function purchase(address purchaser, uint256 inCents)
        internal 
        returns (uint256) {
        
        // Find no.of tokens to be purchased
        uint256 purchaseTokens = inCents.mul(10 ** uint256(decimals)).div(lotsInfo[currLot].rateInCents);
        
        // Check sufficient tokens available in this lot
        uint256 availableTokens = lotsInfo[currLot].totalTokens - lotsInfo[currLot].soldTokens;

        uint256 needToTakeFromTreasury = 0;
        

        // See if required token available in current lot, 
        // if not transfer the balance token from Treasury wallet
        if(availableTokens < purchaseTokens) {
            needToTakeFromTreasury = purchaseTokens - availableTokens;
        }

        // Mint the required tokens
        couponToken.mint(purchaser, purchaseTokens);

        // Transfer from Treasury if needed
        if(needToTakeFromTreasury > 0) {
            remainingTreasuryTokens = remainingTreasuryTokens.sub(needToTakeFromTreasury);
        }
            
        // Add it to Lot Information
        lotsInfo[currLot].soldTokens = lotsInfo[currLot].soldTokens.add(purchaseTokens);
        lotsInfo[currLot].totalCentsRaised = lotsInfo[currLot].totalCentsRaised.add(inCents);

        // See if the buyer is already in our list, add it if not
        uint256 oldTokens = lotsInfo[currLot].buyerInfoForPoolBonus[purchaser].noOfTokensBought;
        if(oldTokens == 0) {
            lotsInfo[currLot].buyersList.push(purchaser);
        }

        // Add total tokens
        lotsInfo[currLot].buyerInfoForPoolBonus[purchaser].noOfTokensBought = 
            lotsInfo[currLot].buyerInfoForPoolBonus[purchaser].noOfTokensBought.add(purchaseTokens);

        // Set bonusEligible as true total purchased units more than POOL_BONUS_ELIGIBLE
        uint256 newTokens = lotsInfo[currLot].buyerInfoForPoolBonus[purchaser].noOfTokensBought;
        if(newTokens >= POOL_BONUS_ELIGIBLE) {
            
            lotsInfo[currLot].buyerInfoForPoolBonus[purchaser].bonusEligible = true;

            if(oldTokens < POOL_BONUS_ELIGIBLE)
                lotsInfo[currLot].cumulativeBonusTokens = lotsInfo[currLot].cumulativeBonusTokens.add(newTokens);
            else
                lotsInfo[currLot].cumulativeBonusTokens = lotsInfo[currLot].cumulativeBonusTokens.add(purchaseTokens);
        }

        // Check if the lot sale is completed
        if(lotsInfo[currLot].soldTokens >= lotsInfo[currLot].totalTokens) {
            // Move to next lot
            currLot++;

            // See now it is in Lot 4
            if(currLot == SALE_LOT4)
                startTimeOfSaleLot4 = now;

            if(currLot == MAX_SALE_LOTS) {
                // All sale lots completed, so end the sale
                endSaleTime = now;
                stage = Stages.Ended;
            } 
        }

        // Check for Referrals
        if(referrals[purchaser] != address(0x0)) {
            // Somebody referred this purchaser, calculate referral bonus and allot it

            // Check whether 5% referral bonus availabe?
            uint256 referralTokensNeeded = purchaseTokens * 5 / 100;    // 5%
            if(remainingReferralTokens >= referralTokensNeeded) {
                // 4% to referree and 1% to purchaser
                couponToken.mint(referrals[purchaser], (purchaseTokens * 4 / 100));
                couponToken.mint(purchaser, (purchaseTokens * 1 / 100));
            }

            // Decrease the total
            remainingReferralTokens = remainingReferralTokens.sub(referralTokensNeeded);
        }

        return purchaseTokens;
    }


    /*
     *
     * Function: calculatePoolBonus()
     *
     */
    function calculatePoolBonus() external onlyOwner {

        // Calculate PoolBonus for all the previous lots of current lot
        for(uint8 i = 0; i < currLot; i++) {
            // Continue the loop of Pool bonus calculated already
            if(lotsInfo[i].poolBonusCalculated == true) continue;

            // contine the loop if nothing to calculate
            if(lotsInfo[i].cumulativeBonusTokens == 0) 
                continue;

            
            // Enumerate and allot bonus
            for(uint32 j = 0; j < lotsInfo[i].buyersList.length; j++) {

                address addr = lotsInfo[i].buyersList[j];
                BuyerInfoForPoolBonus storage buyerInfo = lotsInfo[i].buyerInfoForPoolBonus[addr];
                
                // Bonus eligible?
                if(buyerInfo.bonusEligible) {
                    
                    // Allot bonus tokens                    
                    buyerInfo.bonusTokensAlotted = lotsInfo[i].poolBonus.mul(buyerInfo.noOfTokensBought).div(lotsInfo[i].cumulativeBonusTokens);
                    
                    // Mint the required tokens
                    couponToken.mint(addr, buyerInfo.bonusTokensAlotted);
                }           
            }

            // Mark as Pool Bonus alloted
            lotsInfo[i].poolBonusCalculated = true;

        } // end-of-outer loop

    } // end-of-function


    /*
     *
     * Function: airDrop()
     *
    */
    function airDrop(address[] users, uint256 tokens) 
        external 
        onlyOwner
        atStage(Stages.Started) {

        require(users.length > 0 && tokens > 0);

        uint256 totalTokens = users.length.mul(tokens);

        require(remainingAirDropTokens >= totalTokens);

        for(uint16 i = 0; i < users.length; i++) {

            // Founders address should validate following
            require(users[i] != address(0) && users[i] != fundAddr && users[i] != treasuryAddr && users[i] != contigencyAddr);

             // Mint the required tokens
            couponToken.mint(users[i], tokens);
        }
        // Subtract it from the Remaining tokens
        remainingAirDropTokens = remainingAirDropTokens.sub(totalTokens);
    }

    /*
     *
     * Function: createBounty()
     *
    */
    function createBounty(uint256 noOfTokens)
        external
        onlyOwner
        atStage(Stages.Started) 
        returns (uint32) {

        // Condition
        require(remainingBountyTokens >= noOfTokens);

        // Generate new event id
        uint32 newEventId = uint32(bountyProgram.length);

        bountyProgram.length++;
        bountyProgram[newEventId].tokensForEvent = noOfTokens;

        return newEventId;
    }

    /*
     *
     * Function: killBounty()
     *
    */
    function killBounty(uint32 bountyId)
        external
        onlyOwner
        atStage(Stages.Started) 
        returns (uint32) {
        
        require(
            bountyId < bountyProgram.length && 
            bountyProgram[bountyId].killed == false);

        bountyProgram[bountyId].killed = true;

    }

    /*
     *
     * Function: activateBounty()
     *
    */
    function activateBounty(uint32 bountyId)
        external
        onlyOwner
        atStage(Stages.Started) {

        require(
            bountyId < bountyProgram.length && 
            bountyProgram[bountyId].activated == false && 
            bountyProgram[bountyId].killed == false);

        bountyProgram[bountyId].activated = true;
    }

    /*
     *
     * Function: participateBounty()
     *
    */
    function participateBounty(uint32 bountyId, address user)
        external 
        onlyOwner
        atStage(Stages.Started) {

        // Founders address should validate following
        require(user != address(0) && user != fundAddr && user != treasuryAddr && user != contigencyAddr);

        // Condition
        require(remainingBountyTokens >= bountyProgram[bountyId].tokensForEvent);

        require(
            bountyId < bountyProgram.length &&
            bountyProgram[bountyId].activated == true && 
            bountyProgram[bountyId].killed == false);

        // This user should be participated earlier in this event
        require(bountyProgram[bountyId].userInfoForCampaign[user].participated == false);

        // Mark as participated
        bountyProgram[bountyId].userInfoForCampaign[user].participated = true;
    }


    /*
     *
     * Function: fullfillmentBounty()
     *
    */
    function fullfillmentBounty(uint32 bountyId, address user)
        external 
        onlyOwner
        atStage(Stages.Started) {

        // Condition
        require(remainingBountyTokens >= bountyProgram[bountyId].tokensForEvent);

        require(
            bountyId < bountyProgram.length && 
            bountyProgram[bountyId].activated == true && 
            bountyProgram[bountyId].killed == false);

        // This user should be participated already and fullfilement not done
        require(
            bountyProgram[bountyId].userInfoForCampaign[user].participated == true &&
            bountyProgram[bountyId].userInfoForCampaign[user].fullfillmentDone == false);

        uint256 bountyTokens = bountyProgram[bountyId].tokensForEvent;

         // Mint the required tokens
        couponToken.mint(user, bountyTokens);

        // Subtract it from the Remaining tokens
        remainingBountyTokens = remainingBountyTokens.sub(bountyTokens);

        bountyProgram[bountyId].userInfoForCampaign[user].fullfillmentDone == true;
    }

    /*
     *
     * Function: createCoupon()
     *
    */
    function createCoupon(uint256 noOfTokens)
        external
        onlyOwner
        atStage(Stages.Started) 
        returns (uint32) {

        // Condition
        require(remainingCouponTokens >= noOfTokens);

        // Generate new event id
        uint32 newEventId = uint32(couponProgram.length);

        couponProgram.length++;
        couponProgram[newEventId].tokensForEvent = noOfTokens;

        return newEventId;
    }
    
     /*
     *
     * Function: killCoupon()
     *
    */
    function killCoupon(uint32 couponId)
        external
        onlyOwner
        atStage(Stages.Started) 
        returns (uint32) {
        
        require(
            couponId < couponProgram.length && 
            couponProgram[couponId].killed == false);

        couponProgram[couponId].killed = true;

    }

     /*
     *
     * Function: activateCoupon()
     *
    */
    function activateCoupon(uint32 couponId)
        external
        onlyOwner
        atStage(Stages.Started) {

        require(
            couponId < couponProgram.length && 
            couponProgram[couponId].activated == false && 
            couponProgram[couponId].killed == false);

        couponProgram[couponId].activated = true;
    }

    /*
     *
     * Function: participateCoupon()
     *
    */
    function participateCoupon(uint32 couponId, address user)
        external 
        onlyOwner
        atStage(Stages.Started) {

        // Founders address should validate following
        require(user != address(0) && user != fundAddr && user != treasuryAddr && user != contigencyAddr);

        // Condition
        require(remainingCouponTokens >= couponProgram[couponId].tokensForEvent);

        require(
            couponId < couponProgram.length && 
            couponProgram[couponId].activated == true && 
            couponProgram[couponId].killed == false);

        // This user should be participated earlier in this event
        require(couponProgram[couponId].userInfoForCampaign[user].participated == false);

        // Mark as participated
        couponProgram[couponId].userInfoForCampaign[user].participated = true;
    }

    /*
     *
     * Function: fullfillmentCoupon()
     *
    */
    function fullfillmentCoupon(uint32 couponId, address user)
        external 
        onlyOwner
        atStage(Stages.Started) {

        // Condition
        require(remainingBountyTokens >= couponProgram[couponId].tokensForEvent);

        require(
            couponId < couponProgram.length && 
            couponProgram[couponId].activated == true && 
            couponProgram[couponId].killed == false);

        // This user should be participated already and fullfilement not done
        require(
            couponProgram[couponId].userInfoForCampaign[user].participated == true &&
            couponProgram[couponId].userInfoForCampaign[user].fullfillmentDone == false);

        uint256 bountyTokens = couponProgram[couponId].tokensForEvent;

        // Mint the required tokens
        couponToken.mint(user, bountyTokens);

        // Subtract it from the Remaining tokens
        remainingBountyTokens = remainingBountyTokens.sub(bountyTokens);

        couponProgram[couponId].userInfoForCampaign[user].fullfillmentDone == true;
    }

    /*
     *
     * Function: addReferrer()
     *
    */    
    function addReferrer(address user, address referredBy)
        external
        onlyOwner
        atStage(Stages.Started) {

        require(user != address(0x0) && referredBy != address(0x0));

        require(referrals[user] == address(0x0));

        referrals[user] = referredBy;
    }




    // function TestFunc(uint256 inWei) public view
    //     returns (uint256) {
    //     uint256 contributionInWei = inWei;
    //     uint256 contributioninEth = contributionInWei.div(10 ** uint256(decimals));
    //     uint256 inCents = contributioninEth.mul(rateEth2Cents);
    //     uint256 noOfTokens = inCents.div(lotsInfo[uint8(currLot)].rateInCents);

    //     return noOfTokens;
    // }

    // function TestSign() public pure returns (int8) {
    //     uint8 a = 1;
    //     uint8 b = 2;
    //     return int8(a-b);
    // }
    
}