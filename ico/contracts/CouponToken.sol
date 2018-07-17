
pragma solidity ^0.4.20;

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

    // List for Founders
    mapping(address => uint256) founders;

    // List of Purchaser who participated in Lot1 or Lot2 or Lot3
    mapping(address => uint256) userInLot1to3;

    // List of User who got bonus tokens
    mapping(address => uint256) userBonus;

    
    /*
     *
     * E v e n t s
     *
     */
    event FounderAdded(address indexed founder, uint256 tokens);
    event Mint(address indexed to, uint256 tokens);

    /*
     *
     * M o d i f i e r s
     *
     */
    /*
     * Check if token sale address is not set
     */
    modifier onlyWhenTokenSaleAddrNotSet() {
        require(couponTokenSaleAddr == address(0x0));
        _;
    }

    modifier canMint() {
        require(owner == msg.sender || couponTokenSaleAddr == msg.sender);
        _;
    }

    modifier onlyCallFromCouponTokenSale() {
        require(msg.sender == couponTokenSaleAddr);
        _;
    }

    modifier onlyIfFounderVestingPeriodComplete(address sender) {
        require(IsFounderVestingPeriodOver(sender) == true);
        _;
    }

    modifier onlyIfUserVestingPeriodComplete(address sender) {
        require(IsUserVestingPeriodOver(sender) == true);
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
        returns (bool){

        return super.transferFrom(from, to, value);
    }

    function setContractAddresses(
        address _couponTokenSaleAddr,
        address _couponTokenBountyAddr,
        address _couponTokenCampaignAddr)
        external
        onlyOwner
        onlyWhenTokenSaleAddrNotSet  {

        couponTokenSaleAddr = _couponTokenSaleAddr;
        couponTokenBountyAddr = _couponTokenBountyAddr;
        couponTokenCampaignAddr = _couponTokenCampaignAddr;
    }

    function addFounders(address[] Users, uint256[] Tokens) 
        external 
        onlyCallFromCouponTokenSale {
         // Allocation for founders 
        for(uint i = 0; i < Users.length; i++) { 
            // Assign tokens
            founders[Users[i]] = Tokens[i];

            // Mint the required tokens
            mint(Users[i], Tokens[i]);

            // Emit the event
            emit FounderAdded(Users[i], Tokens[i]);
        }
    }

    function IsFounder(address user)
        external view
        returns(bool) {
        return (founders[user] > 0);
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

    function setUserwhoPurchasedinLot1to3(address user, uint256 tokens)
        external
        onlyCallFromCouponTokenSale {

        userInLot1to3[user] = userInLot1to3[user].add(tokens);
    }

    function setUserwhoGotBonus(address user, uint256 tokens)
        external
        onlyCallFromTokenSaleOrBountyOrCampaign {
        userBonus[user] = userBonus[user].add(tokens);
    }


    function IsFounderVestingPeriodOver(address user)
        internal view
        returns (bool) {

        bool retVal = true;
        if(founders[user] > 0 && now < (endSaleTime + 730 days)) // 2 years
            retVal = false;            

        return retVal;
    }

    function IsUserVestingPeriodOver(address user)
        internal view
        returns (bool) {

        bool retVal = true;
        // See the user participated in lots 1,2 3 or Bouns(Bounty, Campaign, Referral) given, if so
        // he can't do the transfer till the vesting period over
        if((now >= (startTimeOfSaleLot4 + 90 days)) &&          // 3 months
            (userInLot1to3[user] > 0 || userBonus[user] > 0) ) {
            retVal = false;
        }
        
        return retVal;
    }
}