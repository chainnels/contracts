pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";



contract ChainnelsPro is Initializable, UUPSUpgradeable, AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable {
 
    using ECDSAUpgradeable for bytes32;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    bytes32 public constant AUTHORIZED_ROLE = keccak256("AUTHORIZED_ROLE");
    mapping(address => mapping(uint => uint)) public SCTxn;
    address public recipient;
    mapping(address => uint) public referralCount;
    mapping(address => uint) public isWAGMIPro;
   

    mapping(address => uint) public backendNonce;
    mapping(string => bool) public backendReceipt;

    event scComplete(address buyer, uint amount);
    event manualSCComplete(address buyer);
    event backendSCComplete(address buyer,uint nonce, string receipt);
  struct User {
        uint256 totalSparks;
        uint256 dailySparks;
        uint256 startDate;
        uint256 endDate;
    }

    mapping(address => User) public users;
    uint256 public totalAssignedSparks;  // Variable to track total assigned sparks

 
   // uint public sparksMultiplier;
 mapping(address => address) public referrers; 
    mapping(address => bool) public blacklisted; 
    function initialize() public initializer {
      __AccessControlEnumerable_init();
    __ReentrancyGuard_init();
    __UUPSUpgradeable_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(AUTHORIZED_ROLE, msg.sender);
    recipient = payable(msg.sender);
 //   sparksMultiplier=100000000000000;
    }

function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}


//you do not own
function WAGMIProWallet(uint durationMonths, address referrer, address paymentMethod) public payable nonReentrant returns(bool){
    require(SCTxn[paymentMethod][durationMonths]!=0,"Invalid payment method");
            require(!blacklisted[msg.sender], "Address is blacklisted");

   IERC20Upgradeable  scpay = IERC20Upgradeable(paymentMethod);
        require(
          scpay.allowance(msg.sender,address(this)) >= SCTxn[paymentMethod][durationMonths],
            "Please ensure you have approved the required amount to WAGMI"
          ); 
    require(referrer!=address(0) && referrer!=msg.sender,"invalid referrer");
   scpay.transferFrom(msg.sender, recipient, SCTxn[paymentMethod][durationMonths]); 
    
    if(referrer!=address(this)){
        referUser(referrer,durationMonths);
        referUser(msg.sender,durationMonths);
       referralCount[referrer]++;
       referralCount[msg.sender]++;
       referrers[msg.sender] = referrer;

    }
    if(isWAGMIPro[msg.sender]==0 || isWAGMIPro[msg.sender]<=block.timestamp){
    isWAGMIPro[msg.sender]=block.timestamp+86400*((30*durationMonths>365)?365:30*durationMonths);
    }else{
      isWAGMIPro[msg.sender]=isWAGMIPro[msg.sender]-86400*((30*durationMonths>365)?365:30*durationMonths);
    }


     emit scComplete(msg.sender, SCTxn[paymentMethod][durationMonths]);
        return true;
        }



 function manualWAGMIPro(uint durationMonths, address walletAddress, address referrer) public onlyRole(AUTHORIZED_ROLE) nonReentrant returns(bool){
          require(referrer!=address(0) && referrer!=msg.sender && referrer!=walletAddress,"invalid referrer");
                  require(!blacklisted[walletAddress], "Address is blacklisted");

          if(referrer!=address(this)){
                  referUser(referrer,durationMonths);
                  referUser(walletAddress,durationMonths);
                referralCount[referrer]++;
                referralCount[walletAddress]++;
               referrers[msg.sender] = referrer;


              }
  if(isWAGMIPro[walletAddress]==0 || isWAGMIPro[walletAddress]<=block.timestamp){
    isWAGMIPro[walletAddress]=block.timestamp+86400*((30*durationMonths>365)?365:30*durationMonths);
    }else{
      isWAGMIPro[walletAddress]=isWAGMIPro[walletAddress]-86400*((30*durationMonths>365)?365:30*durationMonths);
    }

    emit manualSCComplete(walletAddress);
return true;

 }

 function backendWAGMIPro(uint durationMonths, address referrer, address walletAddress, uint nonce, string memory receipt) onlyRole(AUTHORIZED_ROLE) nonReentrant public returns(bool){
       require(referrer!=address(0) && referrer!=msg.sender && referrer!=walletAddress,"invalid referrer");
       require(backendNonce[walletAddress]<nonce && backendReceipt[receipt]==false,"Already claimed");
       require(!blacklisted[walletAddress], "Address is blacklisted");

       backendNonce[walletAddress]=nonce;
       backendReceipt[receipt]=true;
   
 if(referrer!=address(this)){
         referUser(referrer,durationMonths);
         referUser(walletAddress,durationMonths);
       referralCount[referrer]++;
       referralCount[walletAddress]++;
       referrers[msg.sender] = referrer;

    }
    if(isWAGMIPro[walletAddress]==0 || isWAGMIPro[walletAddress]<=block.timestamp){
    isWAGMIPro[walletAddress]=block.timestamp+86400*((30*durationMonths>365)?365:30*durationMonths);
    }else{
      isWAGMIPro[walletAddress]=isWAGMIPro[walletAddress]-86400*((30*durationMonths>365)?365:30*durationMonths);
    }
  emit backendSCComplete(walletAddress,nonce,receipt);
return true;
 }
//  function setSparksMultiplier(uint _sparksMultiplier) public onlyRole(DEFAULT_ADMIN_ROLE){
//     sparksMultiplier=_sparksMultiplier;
//   }

  ///fix NFT staking to ensure we check if user is WAGMIPro
   function referUser(address _referrer, uint durationMonths) private {
        uint256 runningSparks = (durationMonths>=12)?365:durationMonths*30;
        uint256 dailySparks = 1;
        uint256 startDate = block.timestamp;
        uint256 endDate = startDate + ((durationMonths>=12)?(365*86400):(durationMonths*30*86400));

        // If the referrer has made a referral before and it's not expired
        if (users[_referrer].totalSparks > 0 && block.timestamp <= users[_referrer].endDate) {
            // Calculate the sparks already earned
            uint256 alreadyEarnedSparks = (block.timestamp - users[_referrer].startDate) * users[_referrer].dailySparks;

            // Calculate the remaining sparks
            uint256 remainingSparks = users[_referrer].totalSparks - alreadyEarnedSparks;

            // Update total sparks, daily sparks, and end date
            runningSparks = runningSparks + remainingSparks;
            dailySparks = users[_referrer].dailySparks + 1;
            endDate = block.timestamp + (runningSparks / dailySparks) * 86400;
        }

        // Update total assigned sparks
        totalAssignedSparks += runningSparks;

        users[_referrer] = User(runningSparks, dailySparks, startDate, endDate);
    }


      function getSparksRate(address walletAddress) public view returns(uint){
  
    return (block.timestamp<users[walletAddress].endDate)?users[walletAddress].dailySparks:0;
    }
function getIsWAGMIPro(address userAddress) public view virtual returns(uint){

    return isWAGMIPro[userAddress];
}
    function getReferralCount(address userAddress)public view virtual returns(uint){

    return referralCount[userAddress];
}
  function setPrice(uint _durationMonths, uint _USDPrice, address contractAddress) public onlyRole(AUTHORIZED_ROLE) returns(bool){
      SCTxn[contractAddress][_durationMonths]=_USDPrice;
    return true;
  }

    function changeRecipient(address _recipient) public onlyRole(AUTHORIZED_ROLE) returns(bool){
      recipient=payable(_recipient);
      return true;
  }  
 function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    // Check ERC20 Token Balance
function checkTokenBalance(address _token) public view returns (uint256) {
    return IERC20Upgradeable(_token).balanceOf(address(this));
}

// Check Ether Balance
function checkEtherBalance() public view returns (uint256) {
    return address(this).balance;
}

// Withdraw Ether
function withdrawEther() public onlyRole(DEFAULT_ADMIN_ROLE) {
    payable(msg.sender).transfer(address(this).balance);
}
//withdraw token    
function withdrawToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
    IERC20Upgradeable(_token).transfer(msg.sender, balance);
}
function blacklistWallet(address walletAddress) public onlyRole(AUTHORIZED_ROLE) {
        require(walletAddress != address(0), "Invalid address");
        require(!blacklisted[walletAddress], "Address already blacklisted");

        address referrer = referrers[walletAddress]; // Get the referrer
        if(referrer!=address(0)){
        // Check if walletAddress had contributed to referrer's sparks
        if (users[walletAddress].totalSparks > 0) {
            uint256 oneYearSparks = 365; // This is the contribution of each referral for a year

            // Check if referrer's totalSparks is greater than oneYearSparks
            if (users[referrer].totalSparks >= oneYearSparks) {
                users[referrer].totalSparks -= oneYearSparks;
            } else {
                users[referrer].totalSparks = 0;
            }

            // Recalculate dailySparks and endDate for referrer
            if (users[referrer].totalSparks > 0) {
                users[referrer].dailySparks = users[referrer].totalSparks / ((users[referrer].endDate - users[referrer].startDate) / 86400);
            } else {
                users[referrer].dailySparks = 0;
                users[referrer].endDate = users[referrer].startDate;
            }
        }
        }
        // Reset walletAddress details
        users[walletAddress] = User(0, 0, 0, 0);
        isWAGMIPro[walletAddress] = block.timestamp;

        // Add wallet to blacklist
        blacklisted[walletAddress] = true;
    }
function unbanWallet(address walletAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(walletAddress != address(0), "Invalid address");
        require(blacklisted[walletAddress], "Address not blacklisted");

        // Remove wallet from blacklist
        blacklisted[walletAddress] = false;
    }

}
   




