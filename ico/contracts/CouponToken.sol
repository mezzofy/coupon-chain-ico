
pragma solidity ^0.4.11;

import "./CouponTokenSale.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
//import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

//contract CouponToken is MintableToken {
contract CouponToken is StandardToken, Ownable {
    using SafeMath for uint256;

    string public constant name = "Coupon Chain Token"; 
    string public constant symbol = "CCT";
    uint8 public constant decimals = 18;

    // Address of CouponTokenSale contract
    CouponTokenSale public couponSaleAddr;

    /*
     * Check if token sale address is not set
     */
    modifier onlyWhenTokenSaleAddrNotSet() {
        require(couponSaleAddr == address(0x0));
        _;
    }

    modifier canMint() {
        require(owner == msg.sender || couponSaleAddr == msg.sender);
        _;
    }

    modifier onlyIfFounderVestingPeriodComplete(address sender) {
        require(couponSaleAddr.IsFounderVestingPeriodOver(sender) == true);
        _;
    }

    modifier onlyIfUserVestingPeriodComplete(address sender) {
        require(couponSaleAddr.IsUserVestingPeriodOver(sender) == true);
        _;
    }


    constructor() public {
        balances[msg.sender] = 0;
    }



    /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
    function mint(address _to, uint256 _amount) canMint public returns (bool) {
        
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        //emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /*
     * Transfer token from message sender to another
     *
     * @param to: Destination address
     * @param value: Amount of Coupon token to transfer
     */
    function transfer(address to, uint256 value)
        public
        onlyIfFounderVestingPeriodComplete(msg.sender)
        onlyIfUserVestingPeriodComplete(msg.sender)
        returns (bool) {
        return super.transfer(to, value);
    }

    /*
     * Transfer token from 'from' address to 'to' addreess
     *
     * @param from: Origin address
     * @param to: Destination address
     * @param value: Amount of Coupon Token to transfer
     */
    function transferFrom(address from, address to, uint256 value)
        public
        onlyIfFounderVestingPeriodComplete(from)
        onlyIfUserVestingPeriodComplete(from)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    function setCouponTokenSale(address _couponSaleAddr)
        external
        onlyOwner
        onlyWhenTokenSaleAddrNotSet 
        {

        //uint256 amount = (amountForSale == 0) ? TOKEN_SALE_ALLOWANCE : amountForSale;
        //require(amount <= TOKEN_SALE_ALLOWANCE);

        //approve(_couponSaleAddr, amount);
        couponSaleAddr = CouponTokenSale(_couponSaleAddr);
    }
}