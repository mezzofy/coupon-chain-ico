pragma solidity ^0.4.21;

contract CouponTokenConfig {
    string public constant name = "Coupon Chain Token"; 
    string public constant symbol = "CCT";
    uint8 public constant decimals = 18;

    uint public constant DECIMALSFACTOR = 10 ** uint(decimals);
    uint public constant TOTAL_COUPON_SUPPLY = 1000000000 * DECIMALSFACTOR;

}