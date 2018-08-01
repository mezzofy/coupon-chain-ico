pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./CouponToken.sol";
import "./CouponTokenSaleConfig.sol";

contract CouponTokenSale is Pausable, CouponTokenSaleConfig {
    using SafeMath for uint256;

    // Set the Sales start/end flags
    bool public startSalesFlag;
    bool public endSalesFlag;

    uint256 private rateEth2Cents;

    // Address to collect fund
    address private fundAddr;
    
    // Address for treasury
    address private treasuryAddr;

    // Address of Contigency
    address private contigencyAddr;
    
    // addresses to store bounty and couponCampaign
    address private bountyAddr;
    address private couponCampaignAddr;

    // Founders list
    mapping(address => uint256) founders;
    uint256 totalFounderTokens;                  // total tokens alotted to founders

    // Coupon Token contract address
    CouponToken public couponToken;

    // TreasuryTokens
    uint256 public remainingTreasuryTokens;

    // Remainging PoolBonus Tokens
    uint256 public remainingPoolBonusTokens;

    // Campaigns Tokens
    uint256 public remainingAirDropTokens;
    uint256 public remainingBountyTokens;
    uint256 public remainingCouponTokens;
    uint256 public remainingReferralTokens;

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
        mapping(address => BuyerInfoForPoolBonus) buyerInfo;
        address[] buyersList;
        uint256 cumulativeBonusTokens;
        bool poolBonusCalculated;
        uint256 bonusTokens;
    }

    

    // Mappings for Referrals
    mapping(address => address) referrals;

    // List of Lots information
    mapping(uint8 => LotInfos) lotsInfo;

    // mapping to store bonus(PoolBonus, AirDrop, Boundty, Campaign and Referral) for user
    mapping(address => uint256) userBonusTokens;


    /*
     * Events
     */

    event FounderAdded(address indexed founder, uint256 tokens);

    event EventCrowdSale(string msg);

    event SetEth2Cents(uint rate);


    /*
     * Event for token purchase
     *
     * @param purchaser: Who paid for the tokens
     * @param value: Amount in Wei paid for purchase
     * @param amount: Amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    event BuyFiat(address indexed toUser, uint256 inCents, uint256 purchaseTokens);


    /*
     * Modifiers
     */
    modifier atStage(Stages expectedStage) {
        require(expectedStage == stage);
        _;
    }

    modifier onlyValidAddress(address user) {
        // Should be valid address
        require(IsValidAddress(user));
        _;
    }

    modifier onlyCallFromBounty {
        require(msg.sender == bountyAddr);
        _;
    }

    modifier onlyCallFromCouponCampaign {
        require(msg.sender == couponCampaignAddr);
        _;
    }

    modifier onlyCallFromBonusContracts {
        require(
            msg.sender == address(this) ||
            msg.sender == bountyAddr    ||
            msg.sender == couponCampaignAddr);
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
        stage = Stages.Init;

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

        // Init PoolBonus Token
        remainingPoolBonusTokens = MAX_CAP_POOLBONUS;

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
     * SetupSale with addresses
     */
    function setupSale(address _fundAddr, address _treasuryAddr, address _contigencyAddr) 
        external
        onlyOwner
        atStage(Stages.Init) {

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
        external 
        onlyOwner 
        atStage(Stages.Setup) {

        // Both array length should be same
        require(Users.length > 0 && Users.length == Tokens.length);

        // Check the total amount should not cross the MAX_CAP_FOR_FOUNDERS
        uint256 totalFounderAllocation = 0;
        for(uint i = 0; i < Tokens.length; i++) { 
            totalFounderAllocation = totalFounderAllocation.add(Tokens[i]);

            // Founders address should validate following
            require(
                Users[i] != address(0) && 
                Users[i] != owner &&
                Users[i] != fundAddr && 
                Users[i] != treasuryAddr && 
                Users[i] != contigencyAddr && 
                Tokens[i] > 0);
        }
        
        // Total tokens should be more than CAP
        require(totalFounderAllocation <= MAX_CAP_FOR_FOUNDERS);

         // Allocation for founders 
        for(i = 0; i < Users.length; i++) { 
            
            // Mint the required tokens
            couponToken.mint(Users[i], Tokens[i]);

            // Add it to Founder mapping
            founders[Users[i]] = Tokens[i];

            // Set this user as Founder for Vesting period checking
            couponToken.setFounderUser(Users[i]);

            // Add tokens to variable
            totalFounderTokens = totalFounderTokens.add(Tokens[i]);

            // Emit the event
            emit FounderAdded(Users[i], Tokens[i]);
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

        emit SetEth2Cents(rate);

    }

    /*
     * Start sale
     */
    function startSale()
        external
        onlyOwner
        atStage(Stages.Setup)
    {
        require(rateEth2Cents > 0);
        
        stage = Stages.Started;
        currLot = SALE_LOT1;
        startSalesFlag = true;

        // Fire the event
        emit EventCrowdSale("Sales Started");
    }

     /*
     * End sale
     */
    function endSale() 
        external
        onlyOwner {

        // Flag to prevent the second call of this function
        require(endSalesFlag == false);

        // Sale-stage should be started or auto-ended in Lot4 Sales
        require(stage == Stages.Started || stage == Stages.Ended);

        // Sale is going to end, so force calculate bonus for un-finished sale-lots aswell
        calcPoolBonus(MAX_SALE_LOTS);


        // Allocate tokens for contigency
        couponToken.mint(contigencyAddr, MAX_CAP_FOR_CONTIGENCY);

        /* Calculate remaining balance for Treasury
         *  AirDropTokens, BountyTokens, ReferralTokens and CouponTokens are the subset of Treasury balace
         */
        uint256 treasuryTokens = remainingTreasuryTokens - 
            (MAX_CAP_POOLBONUS - remainingPoolBonusTokens) -
            (MAX_CAP_AIRDROP_PROGRAM - remainingAirDropTokens) - 
            (MAX_CAP_BOUNTY_PROGRAM - remainingBountyTokens) -
            (MAX_CAP_REFERRAL_PROGRAM - remainingReferralTokens) -
            (MAX_CAP_COUPON_PROGRAM - remainingCouponTokens);

        
        for(uint8 i = 0; i<MAX_SALE_LOTS; i++) {
            LotInfos memory linfo = lotsInfo[i];
            // Check all poolBonus tokens are issued, if not it should goto treasury a/c    
            //treasuryTokens = treasuryTokens.add(linfo.poolBonus - linfo.bonusTokens);

            // Unsold tokens should goto treasury a/c
            if(linfo.totalTokens > linfo.soldTokens)
                treasuryTokens = treasuryTokens.add(linfo.totalTokens - linfo.soldTokens);
        }

        // mint the balance to Treasury wallet
        couponToken.mint(treasuryAddr, treasuryTokens);

        // Check if sale already end by purchase
        if(stage == Stages.Started) {
            couponToken.setSalesEndTime(now);
            stage = Stages.Ended;
        }

        endSalesFlag = true;
        emit EventCrowdSale("Sales Ended");
    }


    /*
     * Function: buy()
     */
    function buy()
        public 
        payable
        whenNotPaused
        onlyValidAddress(msg.sender)
        atStage(Stages.Started)  {

        address purchaser = msg.sender;
        uint256 contributionInWei = msg.value;
        uint256 inCents = contributionInWei.mul(rateEth2Cents); // in units of 10^18

         // Find no.of tokens to be purchased
        uint256 purchaseTokens = inCents.div(lotsInfo[currLot].rateInCents);

        // Call purchase function
        purchase(purchaser, purchaseTokens);

        // Transfer contributions to fund address
        fundAddr.transfer(contributionInWei);

        // Emit the status
        emit TokenPurchase(purchaser, contributionInWei, purchaseTokens);
    }

    /*
     * Function: buyFiat()
     */
    function buyFiat(address toUser, uint256 inCents) 
        public
        onlyOwner
        whenNotPaused
        onlyValidAddress(toUser)
        atStage(Stages.Started) {

        // Find no.of tokens to be purchased
        uint256 purchaseTokens = inCents.mul(10 ** uint256(decimals)).div(lotsInfo[currLot].rateInCents);

        // Call purchase()    
        purchase(toUser, purchaseTokens);

        // Emit the notification
        emit BuyFiat(toUser, inCents, purchaseTokens);

    }

    /*
     * Function: purchase()
     */

    function purchase(address purchaser, uint256 purchaseTokens)
        internal {
        
        // Find no.of tokens to be purchased
        //uint256 purchaseTokens = inCents.mul(10 ** uint256(decimals)).div(lotsInfo[currLot].rateInCents);
        
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

        // Update buyer to CouponToken contract to calculate vesting period(only for Sale-lot1 to Sale-lot3)
        if(currLot != SALE_LOT4)
            couponToken.setSalesUser(purchaser);

        // Transfer from Treasury if needed
        if(needToTakeFromTreasury > 0) {
            remainingTreasuryTokens = remainingTreasuryTokens.sub(needToTakeFromTreasury);
        }
            
        // Add it to Lot Information
        lotsInfo[currLot].soldTokens = lotsInfo[currLot].soldTokens.add(purchaseTokens);
        //lotsInfo[currLot].totalCentsRaised = lotsInfo[currLot].totalCentsRaised.add(inCents);

        // See if the buyer is already in our list, add it if not
        uint256 oldTokens = lotsInfo[currLot].buyerInfo[purchaser].noOfTokensBought;
        if(oldTokens == 0) {
            lotsInfo[currLot].buyersList.push(purchaser);
        }

        // Add total tokens
        lotsInfo[currLot].buyerInfo[purchaser].noOfTokensBought = 
            lotsInfo[currLot].buyerInfo[purchaser].noOfTokensBought.add(purchaseTokens);

        // Set bonusEligible as true total purchased units more than POOL_BONUS_ELIGIBLE
        uint256 newTokens = lotsInfo[currLot].buyerInfo[purchaser].noOfTokensBought;
        if(newTokens >= POOL_BONUS_ELIGIBLE) {
            
            lotsInfo[currLot].buyerInfo[purchaser].bonusEligible = true;

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
                couponToken.setSaleLot4StartTime(now);

            if(currLot == MAX_SALE_LOTS) {
                // All sale lots completed, so end the sale
                couponToken.setSalesEndTime(now);
                stage = Stages.Ended;
                //emit EventCrowdSale("Sales Ended");
            } 
        }

        //
        // Calculate referral bonus
        //
        // Check for Referrals
        address refereeAddr = referrals[purchaser];
        if(refereeAddr != address(0x0)) {
            // Somebody referred this purchaser, calculate referral bonus and allot it

            // Check whether 5% referral bonus availabe?
            uint256 referralTokensNeeded = purchaseTokens.mul(5).div(100);         // 5%

            if(remainingReferralTokens < referralTokensNeeded) {
                // No sufficient referral bonus available, borrow it from Treasury a/c
                needToTakeFromTreasury = referralTokensNeeded.sub(remainingReferralTokens);

                //Subtract it from Remaining treasury tokens
                remainingTreasuryTokens = remainingTreasuryTokens.sub(needToTakeFromTreasury);

                // Reset Referral token with available token
                referralTokensNeeded = remainingReferralTokens;
            }
            
            // 4% to referree and 1% to purchaser
            uint256 bonusReferral = purchaseTokens.mul(4).div(100);           // 4%
            uint256 bonusPurchaser = purchaseTokens.mul(1).div(100);          // 1%

            // mint the bonus tokens and transfer to Referee and purchaser
            couponToken.mint(refereeAddr, bonusReferral);
            couponToken.mint(purchaser, bonusPurchaser);

            // Add it to bonus as well
            this.addBonusTokens(refereeAddr, bonusReferral);
            this.addBonusTokens(purchaser, bonusPurchaser);

            // Decrease the total
            remainingReferralTokens = remainingReferralTokens.sub(referralTokensNeeded);
            
        }
    }


    /*
     *
     * Function: calculatePoolBonus()
     *
     */
    function calculatePoolBonus() external onlyOwner {
        // Calculate PoolBounus till the previous Sale lot
        calcPoolBonus(currLot);
    }


     /*
     *
     * Function: calcPoolBonus()
     *
     */
    function calcPoolBonus(uint8 _currLot) internal {

        // Calculate PoolBonus for all the previous lots of current lot
        for(uint8 i = 0; i < _currLot; i++) {
            // Continue the loop if Pool bonus calculated already
            if(lotsInfo[i].poolBonusCalculated == true) continue;

            // contine the loop if nothing to calculate
            if(lotsInfo[i].cumulativeBonusTokens > 0) { 
                // Enumerate and allot bonus
                for(uint32 j = 0; j < lotsInfo[i].buyersList.length; j++) {

                    address buyer = lotsInfo[i].buyersList[j];
                    BuyerInfoForPoolBonus memory buyerInfo = lotsInfo[i].buyerInfo[buyer];
                    
                    // Bonus eligible?
                    if(buyerInfo.bonusEligible) {
                        
                        // Allot bonus tokens                    
                        buyerInfo.bonusTokensAlotted = lotsInfo[i].poolBonus.mul(buyerInfo.noOfTokensBought).div(lotsInfo[i].cumulativeBonusTokens);

                        // Add it to bonus as well
                        this.addBonusTokens(buyer, buyerInfo.bonusTokensAlotted);
                        
                        // Add it to LotInfo as well
                        lotsInfo[i].bonusTokens = lotsInfo[i].bonusTokens.add(buyerInfo.bonusTokensAlotted);

                        // Mint the required tokens
                        couponToken.mint(buyer, buyerInfo.bonusTokensAlotted);
                    }           
                }
                remainingPoolBonusTokens = remainingPoolBonusTokens.sub(lotsInfo[i].bonusTokens);
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
            // Should be valid address
            require(IsValidAddress(users[i]));
        }



        for(i = 0; i < users.length; i++) {

             // Mint the required tokens
            couponToken.mint(users[i], tokens);

            // Set this user as bonus alloted
            couponToken.setBonusUser(users[i]);

            // Add it to bonus as well
            this.addBonusTokens(users[i], tokens);
        }
        // Subtract it from the Remaining tokens
        remainingAirDropTokens = remainingAirDropTokens.sub(totalTokens);
    }

    /*
     * 
     * Function: setBountyAddr()
     *
     */
    function setBountyAddr(address _bountyAddr) 
        external
        onlyOwner {
        bountyAddr = _bountyAddr;
    }

    /*
     * 
     * Function: setBountyAddr()
     *
     */
    function setCampaignAddr(address _campaignAddr) 
        external
        onlyOwner {
        couponCampaignAddr = _campaignAddr;
    }


    /*
     * 
     * Function: subtractBountyTokens()
     *
     */
    function subtractBountyTokens(uint256 noOfTokens)
        external 
        onlyCallFromBounty {
        remainingBountyTokens = remainingBountyTokens.sub(noOfTokens);
    }

    /*
     * 
     * Function: subtractCampaignTokens()
     *
     */
    function subtractCampaignTokens(uint256 noOfTokens)
        external 
        onlyCallFromCouponCampaign {
        remainingCouponTokens = remainingCouponTokens.sub(noOfTokens);
    }
 
    /*
     *
     * Function: addReferrer()
     *
    */    
    function addReferrer(address user, address referredBy)
        external
        onlyOwner
        onlyValidAddress(user)
        onlyValidAddress(referredBy)
        atStage(Stages.Started) {

        // Should not be 0
        require(user != address(0) && referredBy != address(0));
        
	// Should not be the same address
        require(user != referredBy);

        // Should be referred only once
        require(referrals[user] == address(0));

        referrals[user] = referredBy;
    }

    /*
     *
     * Function: addBonusTokens()
     *
    */  
    function addBonusTokens(address user, uint256 tokens)
        public
        onlyCallFromBonusContracts {
        
        userBonusTokens[user] = userBonusTokens[user].add(tokens);

    }

    //*************************************************************************/
    //
    //
    // F U N C T I O N S   C AL L E D   O NL Y   F RO M   C OU P O N   TO K E N 
    //
    //
    //*************************************************************************/
    function IsValidAddress(address user) 
        public view
        returns (bool) {

        return (
            user != address(0) &&       // Should not be 0
            user != owner &&            // Should not be owner
            user != fundAddr &&         // Should not be Fund address
            user != treasuryAddr &&     // Should not be Treasury address
            user != contigencyAddr &&   // Should not be Contigency address
            founders[user] == 0         // Should not be founder
        );
    }

    /*************************************************************************
     *
     *
     *  F u n c t i o n s   f o r   D a s h b o a r d   A c c e s s 
     *
     *
    *************************************************************************/
    function dashboardGetAllIssuedTokens() 
        external view
        returns (uint256 tokenSold, uint256 tokenBonus, uint256 tokenAirDrop, 
        uint256 tokenBounty, uint256 tokenCampaign, uint256 tokenReferral, uint256 tokenFounder) {

        //
        // Calculate return values
        tokenSold = lotsInfo[SALE_LOT1].soldTokens + lotsInfo[SALE_LOT2].soldTokens + 
        lotsInfo[SALE_LOT3].soldTokens + lotsInfo[SALE_LOT4].soldTokens;

        tokenBonus = lotsInfo[SALE_LOT1].bonusTokens + lotsInfo[SALE_LOT2].bonusTokens + 
        lotsInfo[SALE_LOT3].bonusTokens + lotsInfo[SALE_LOT4].bonusTokens;

        tokenAirDrop = (MAX_CAP_AIRDROP_PROGRAM - remainingAirDropTokens);
        tokenBounty = (MAX_CAP_BOUNTY_PROGRAM - remainingBountyTokens);
        tokenCampaign = (MAX_CAP_COUPON_PROGRAM - remainingCouponTokens);
        tokenReferral = (MAX_CAP_REFERRAL_PROGRAM - remainingReferralTokens);

        // Token Founders
        tokenFounder = totalFounderTokens;
    }

    function dasboardGetCurrentSaleLot() 
        external view
        returns (uint8) {
        
        // Return current Sale Lot number
        return currLot; // Change it to 1 based index
    }

    function dashboardGetSaleLotSales(uint8 lotNumber)
        external view
        returns (uint256) {

        require(lotNumber >= SALE_LOT1 && lotNumber <= SALE_LOT4);

        return lotsInfo[lotNumber].soldTokens;

    }


    function dashboardGetPurchasedTokensAndBonus(address user)
        external view
        returns (uint256 tokensPurchased, uint256 tokensBouns) {

        // Calculate Purchased tokens
        tokensPurchased = lotsInfo[SALE_LOT1].buyerInfo[user].noOfTokensBought +
        lotsInfo[SALE_LOT2].buyerInfo[user].noOfTokensBought +
        lotsInfo[SALE_LOT3].buyerInfo[user].noOfTokensBought +
        lotsInfo[SALE_LOT4].buyerInfo[user].noOfTokensBought;

        // Calculate Bouns tokens
        tokensBouns = userBonusTokens[user];
    }
}