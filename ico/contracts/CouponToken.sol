pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./StandardToken.sol";
import "./Ownable.sol";

import "./CouponTokenConfig.sol";

//contract CouponToken is MintableToken {
contract CouponToken is StandardToken, Ownable, CouponTokenConfig {
    using SafeMath for uint256;

    // Start time of the Sale-lot 4
    uint256 public startTimeOfSaleLot4;

    // End time of Sale
    uint256 public endSaleTime;

    // Address of CouponTokenSale contract
    address public couponTokenSaleAddr;

    // Address of CouponTokenBounty contract
    address public couponTokenBountyAddr;

    // Address of CouponTokenCampaign contract
    address public couponTokenCampaignAddr;


    // List of User for Vesting Period 
    mapping(address => uint8) vestingUsers;

    /*
     *
     * E v e n t s
     *
     */
    event Mint(address indexed to, uint256 tokens);

    /*
     *
     * M o d i f i e r s
     *
     */

    modifier canMint() {
        require(
            couponTokenSaleAddr == msg.sender ||
            couponTokenBountyAddr == msg.sender ||
            couponTokenCampaignAddr == msg.sender);
        _;
    }

    modifier onlyCallFromCouponTokenSale() {
        require(msg.sender == couponTokenSaleAddr);
        _;
    }

    modifier onlyIfValidTransfer(address sender) {
        require(isTransferAllowed(sender) == true);
        _;
    }

    modifier onlyCallFromTokenSaleOrBountyOrCampaign() {
        require(
            msg.sender == couponTokenSaleAddr ||
            msg.sender == couponTokenBountyAddr ||
            msg.sender == couponTokenCampaignAddr);
        _;
    }


    /*
     *
     * C o n s t r u c t o r
     *
     */
    constructor() public {
        balances[msg.sender] = 0;
    }


    /*
     *
     * F u n c t i o n s
     *
     */
    /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
    function mint(address _to, uint256 _amount) canMint public {
        
        require(totalSupply_.add(_amount) <= TOTAL_COUPON_SUPPLY);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    /*
     * Transfer token from message sender to another
     *
     * @param to: Destination address
     * @param value: Amount of Coupon token to transfer
     */
    function transfer(address to, uint256 value)
        public
        onlyIfValidTransfer(msg.sender)
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
        onlyIfValidTransfer(from)
        returns (bool){

        return super.transferFrom(from, to, value);
    }

    function setContractAddresses(
        address _couponTokenSaleAddr,
        address _couponTokenBountyAddr,
        address _couponTokenCampaignAddr)
        external
        onlyOwner
    {
        couponTokenSaleAddr = _couponTokenSaleAddr;
        couponTokenBountyAddr = _couponTokenBountyAddr;
        couponTokenCampaignAddr = _couponTokenCampaignAddr;
    }


    function setSalesEndTime(uint256 _endSaleTime) 
        external
        onlyCallFromCouponTokenSale  {
        endSaleTime = _endSaleTime;
    }

    function setSaleLot4StartTime(uint256 _startTime)
        external
        onlyCallFromCouponTokenSale {
        startTimeOfSaleLot4 = _startTime;
    }


    function setFounderUser(address _user)
        public
        onlyCallFromCouponTokenSale {
        // Add vesting user as Founder
        vestingUsers[_user] = USER_FOUNDER;
    }

    function setSalesUser(address _user)
        public
        onlyCallFromCouponTokenSale {
        // Add vesting user under sales purchase
        vestingUsers[_user] = USER_BUYER;
    }

    function setBonusUser(address _user) 
        public
        onlyCallFromTokenSaleOrBountyOrCampaign {
        // Set this user as who got bonus
        vestingUsers[_user] = USER_BONUS;
    }

    function isTransferAllowed(address _user)
        internal view
        returns (bool) {
        bool retVal = true;
        if(vestingUsers[_user] == USER_FOUNDER) {
            if(endSaleTime == 0 ||                // See whether sale is over?
                (now < (endSaleTime + 730 days))) // 2 years
                retVal = false;
        }
        else if(vestingUsers[_user] == USER_BUYER || vestingUsers[_user] == USER_BONUS) {
            if(startTimeOfSaleLot4 == 0 ||              // See if the SaleLot4 started?
                (now < (startTimeOfSaleLot4 + 90 days)))
                retVal = false;
        }
        return retVal;
    }
}