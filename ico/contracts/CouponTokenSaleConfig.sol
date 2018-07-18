pragma solidity ^0.4.21;

contract CouponTokenSaleConfig {
/*
     *
     * C O N S T A N T S
     *
    */
    uint8 public constant decimals = 18;

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
    uint8 constant MAX_SALE_LOTS = 4;
    uint8 constant SALE_LOT1 = 0;
    uint8 constant SALE_LOT2 = 1;
    uint8 constant SALE_LOT3 = 2;
    uint8 constant SALE_LOT4 = 3;

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
}