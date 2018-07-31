pragma solidity ^0.4.24;

contract CouponTokenConfig {
    string public constant name = "Coupon Chain Token"; 
    string public constant symbol = "CCT";
    uint8 public constant decimals = 18;

    uint256 internal constant DECIMALS_FACTOR = 10 ** uint(decimals);
    uint256 internal constant TOTAL_COUPON_SUPPLY = 1000000000 * DECIMALS_FACTOR;

    uint8 constant USER_NONE = 0;
    uint8 constant USER_FOUNDER = 1;
    uint8 constant USER_BUYER = 2;
    uint8 constant USER_BONUS = 3;

}