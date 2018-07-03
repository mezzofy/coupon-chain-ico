pragma solidity ^0.4.20;

import "./CouponToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract CouponTokenSale is Pausable {
    using SafeMath for uint256;

    // Start time of Sale
    uint256 public startTime;

    // Start time of the Sale-lot 4
    uint256 public startTimeOfSaleLot4;

    // End time of Sale
    uint256 public endTime;

    // Sales ended 
    bool public salesEnded;

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

    /*
     *
     * C O N S T A N T S
     *
    */
    uint8 public constant decimals = 18;
    
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
        address addr;
        uint256 noOfTokensBought;
    }

    // Information related to lots
    struct LotInfos {
        uint256 totalTokens;
        uint256 rateInCents;
        uint256 poolBonus;
        uint256 soldTokens;
        uint256 totalCentsRaised;
        BuyerInfoForPoolBonus[] buyerInfoForPoolBonus;
    }

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
     * Event for sale end logging
     *
     * @param endTime: End date of sale
     * @param totalWeiRaised: Total amount of raised in Wei after sale ended
     * 
     */
    event SaleEnded(uint256 endTime, uint256 totalWeiRaised);

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
        require(now >= startTime);

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

        // Initialise the saleEnded with false
        salesEnded = false;

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

        // Allocate tokens for treasury
        if (!couponToken.mint(treasuryAddr, MAX_CAP_FOR_TREASURY)) {
            revert();
        }

        // Allocate tokens for contigency
        if (!couponToken.mint(contigencyAddr, MAX_CAP_FOR_CONTIGENCY)) {
            revert();
        }

        // Change the Stage as Setup
        stage = Stages.Setup;

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
     * Allocation to Founders
     *
     */
    function addFounders(address[] Users, uint256[] Tokens)
        public 
        onlyOwner 
        atStage(Stages.Setup) {

        // Both array length should be same
        require(Users.length == Tokens.length);

        // Check the total amount should not cross the MAX_CAP_FOR_FOUNDERS
        uint256 totalFounderAllocation = 0;
        for(uint i = 0; i < Tokens.length; i++) { 
            totalFounderAllocation = totalFounderAllocation.add(Tokens[i]);

            // Founders address should validate following
            require(Users[i] != address(0) && Users[i] != fundAddr && Users[i] != treasuryAddr && Users[i] != contigencyAddr);
        }
        
        // Total tokens should be more than CAP
        require(totalFounderAllocation <= MAX_CAP_FOR_FOUNDERS);
        
        // Allocation for founders 
        for(i = 0; i < Users.length; i++) { 
            // Assign tokens
            founders[Users[i]] = Tokens[i];

            // Mint the required token
            if (!couponToken.mint(Users[i], Tokens[i])) {
                revert();
            }
        }
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
        startTime = now;

        // Fire the event
        emit SaleStarted(startTime);
    }

     /*
     * End sale
     */
    function endSale() external onlyOwner atStage(Stages.Started) {
        endTime = now;
        stage = Stages.Ended;

        emit SaleEnded(endTime, totalWeiRaised);
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
        uint256 totalTokens = inCents.div(lotsInfo[currLot].rateInCents) * (10 ** uint256(decimals));
        
        // Check sufficient tokens available in this lot
        uint256 availableTokens = lotsInfo[currLot].totalTokens - lotsInfo[currLot].soldTokens;

        uint256 purchaseToken;
        uint256 needToTakeFromTreasury = 0;
        

        // See if required token available in current lot, 
        // if not transfer the balance token from Treasury wallet
        if(availableTokens >= totalTokens) {
            purchaseToken = totalTokens;
        } else {
            purchaseToken = availableTokens;
            needToTakeFromTreasury = totalTokens - availableTokens;
        }

        // Mint the required tokes
        if (!couponToken.mint(purchaser, purchaseToken)) {
            revert();
        }

        // Transfer from Treasury if needed
        if(needToTakeFromTreasury > 0) {
            if (!couponToken.transferFrom(treasuryAddr, purchaser, needToTakeFromTreasury)) {
                revert();
            }
        }
            
        // Add it to Lot Information
        lotsInfo[currLot].soldTokens = lotsInfo[currLot].soldTokens.add(purchaseToken + needToTakeFromTreasury);
        lotsInfo[currLot].totalCentsRaised = lotsInfo[currLot].totalCentsRaised.add(inCents);

        BuyerInfoForPoolBonus memory buyer = BuyerInfoForPoolBonus(purchaser, totalTokens);
        
        // See the buyer already in list
        for(uint i = 0; i < lotsInfo[currLot].buyerInfoForPoolBonus.length; i++) {
            if(lotsInfo[currLot].buyerInfoForPoolBonus[i].addr == buyer.addr) {
                lotsInfo[currLot].buyerInfoForPoolBonus[i].noOfTokensBought = lotsInfo[currLot].buyerInfoForPoolBonus[i].noOfTokensBought.add(totalTokens);
                break; // break the for-loop
            }
        }
        
        if(i == lotsInfo[currLot].buyerInfoForPoolBonus.length) {
            // Item not found in the array, so add it
            lotsInfo[currLot].buyerInfoForPoolBonus.push(buyer);
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
                stage = Stages.Ended;
            } 
        }

        return totalTokens;
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
    
} //** End of Contract