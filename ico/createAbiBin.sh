# copy openzeppelin-solidity folder first
echo "Coping openzepplin-solidity folder..."
cp -r node_modules/openzeppelin-solidity .

# Create abi/bin for CouponToken.sol
echo "Creating abi and bin files for CouponToken.sol..."
solcjs --optimize --bin --abi -o ./abi-bin contracts/CouponToken.sol contracts/CouponTokenConfig.sol openzeppelin-solidity/contracts/math/SafeMath.sol openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol openzeppelin-solidity/contracts/ownership/Ownable.sol openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol openzeppelin-solidity/contracts/token/ERC20/ERC20.sol openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

# Create abi/bin for CouponTokenSale.sol
echo "Creating abi and bin files for CouponTokenSale.sol..."
solcjs --optimize --bin --abi -o ./abi-bin contracts/CouponTokenSale.sol contracts/CouponToken.sol contracts/CouponTokenConfig.sol contracts/CouponTokenSaleConfig.sol openzeppelin-solidity/contracts/math/SafeMath.sol openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol openzeppelin-solidity/contracts/token/ERC20/ERC20.sol openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol openzeppelin-solidity/contracts/lifecycle/Pausable.sol openzeppelin-solidity/contracts/ownership/Ownable.sol

# Create abi/bin for CouponTokenBount.sol
echo "Creating abi and bin files for CouponTokenBounty.sol..."
solcjs --optimize --bin --abi -o ./abi-bin contracts/CouponTokenBounty.sol contracts/CouponTokenSale.sol contracts/CouponToken.sol contracts/CouponTokenConfig.sol contracts/CouponTokenSaleConfig.sol openzeppelin-solidity/contracts/math/SafeMath.sol openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol openzeppelin-solidity/contracts/token/ERC20/ERC20.sol openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol openzeppelin-solidity/contracts/lifecycle/Pausable.sol openzeppelin-solidity/contracts/ownership/Ownable.sol

# Create abi/bin for CouponTokenCampaign.sol
echo "Creating abi and bin files for CouponTokenCampain.sol..."
solcjs --optimize --bin --abi -o ./abi-bin contracts/CouponTokenCampaign.sol contracts/CouponTokenSale.sol contracts/CouponToken.sol contracts/CouponTokenConfig.sol contracts/CouponTokenSaleConfig.sol openzeppelin-solidity/contracts/math/SafeMath.sol openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol openzeppelin-solidity/contracts/token/ERC20/ERC20.sol openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol openzeppelin-solidity/contracts/lifecycle/Pausable.sol openzeppelin-solidity/contracts/ownership/Ownable.sol 

echo "Removing openzepplin-solidity folder"
rm -rf openzeppelin-solidity

