import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity >=0.8.2 <0.9.0;

contract ChainnelsKeysV1 is Ownable {
    address public protocolFeeDestination;
    address public holderFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public creatorFeePercent;
    uint256 public referrerFeePercent;
    uint256 public holderFeePercent;
    uint256 public keyTypeRange;
event Trade(
    uint256 indexed txNonce,
    address indexed trader,
    address indexed creator,
    bool isBuy,
    uint256 shareAmount,
    uint256 ethAmount,
    uint256 supply,
    uint keyType,
    uint timestamp
);    constructor() Ownable(){
        holderFeeDestination = msg.sender;
        protocolFeeDestination = msg.sender;
        protocolFeePercent = 50000000000000000;
        creatorFeePercent = 50000000000000000;
        holderFeePercent = 50000000000000000;
        referrerFeePercent = 50000000000000000;
        keyTypeRange=2;
    }
    struct TransactionDetails {
    address trader;
    address creator;
    bool isBuy;
    uint256 shareAmount;
    uint256 ethAmount;
    uint256 supply;
    uint256 keyType; //change to string to allow random groups
    uint timestamp;
}
uint256 public nonce = 0;

// 2. Create a mapping of nonce to the struct.
mapping(uint256 => TransactionDetails) public transactions;
    // KeyCreator =>(KeyType => (Holder => Balance))
    mapping(address => mapping(uint=>mapping(address => uint256))) public keysBalance;

    // KeyCreator =>(KeyType => Supply)
        mapping(address => mapping(uint=>uint256)) public keyHolderCount;

    mapping(address => mapping(uint=>uint256)) public keysSupply;
    function setHolderDestination(address _feeDestination) public onlyOwner {
                holderFeeDestination = _feeDestination;

    }
    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
    }

    function setCreatorFeePercent(uint256 _feePercent) public onlyOwner {
        creatorFeePercent = _feePercent;
    }

    function setReferrerFeePercent(uint256 _feePercent) public onlyOwner {
        referrerFeePercent = _feePercent;
    }
     function setHolderFeePercent(uint256 _feePercent) public onlyOwner {
        holderFeePercent = _feePercent;
    }
    function setKeyTypes(uint256 _keyTypes) public onlyOwner{
        keyTypeRange=_keyTypes;

    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    function getBuyPrice(address keysCreator, uint256 amount, uint keyType) public view returns (uint256) {
        return getPrice(keysSupply[keysCreator][keyType], amount);
    }

    function getSellPrice(address keysCreator, uint256 amount, uint keyType) public view returns (uint256) {
        return getPrice(keysSupply[keysCreator][keyType] - amount, amount);
    }

    function getBuyPriceAfterFee(address keysCreator, uint256 amount, uint keyType) public view returns (uint256) {
        uint256 price = getBuyPrice(keysCreator, amount, keyType);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 creatorFee = price * creatorFeePercent / 1 ether;
       uint256 holderFee = price * holderFeePercent / 1 ether;

        return price + protocolFee + creatorFee + holderFee;
    }

    function getSellPriceAfterFee(address keysCreator, uint256 amount, uint keyType) public view returns (uint256) {
        uint256 price = getSellPrice(keysCreator, amount, keyType);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 creatorFee = price * creatorFeePercent / 1 ether;
        return price - protocolFee - creatorFee;
    }

    function buyKey(address keysCreator, uint256 amount, address referrer, uint keyType) public payable {
        uint256 supply = keysSupply[keysCreator][keyType];
        require(keyType>=1 && keyType<=keyTypeRange,"Invalid key Type");
         require(amount>=1, "You have to buy at least one key");
        require(supply > 0 || keysCreator == msg.sender, "Only the keys' creator can buy the first key");
        uint256 price = getPrice(supply, amount);
         uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 creatorFee = price * creatorFeePercent / 1 ether;
        uint256 holderFee = price * holderFeePercent / 1 ether;
        require(msg.value >= price + protocolFee + creatorFee + holderFee, "Insufficient payment");
        if(keysBalance[keysCreator][keyType][msg.sender]==0){
        keyHolderCount[keysCreator][keyType]++;
        }
        keysBalance[keysCreator][keyType][msg.sender] +=  amount;
        keysSupply[keysCreator][keyType] = supply + amount;
        nonce++;
         uint timestamp=block.timestamp;
        transactions[nonce] = TransactionDetails(msg.sender, keysCreator, true, amount, price, supply + amount, keyType, timestamp);
        emit Trade(nonce, msg.sender, keysCreator, true, amount, price, supply + amount,keyType, timestamp);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee- (protocolFee * referrerFeePercent / 1 ether)}("");
        (bool success2, ) = keysCreator.call{value: creatorFee}("");
          (bool success3, ) = holderFeeDestination.call{value: holderFee }("");
        (bool success4, ) = referrer.call{value: (protocolFee * referrerFeePercent / 1 ether)}("");
        require(success1 && success2 && success3 && success4, "Unable to send funds");
    
      
    }

    function sellKey(address keysCreator, uint256 amount, uint keyType) public payable {
        require(keyType>=1 && keyType<=keyTypeRange,"Invalid key Type");
        require(amount>=1, "You have to sell at least one key");
        uint256 supply = keysSupply[keysCreator][keyType];
        if(keysCreator == msg.sender){
        require(keysBalance[keysCreator][keyType][msg.sender] > amount, "Creator cannot sell their last key");
        }
        require(supply > amount, "Cannot sell the last key");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 creatorFee = price * creatorFeePercent / 1 ether;
        require(keysBalance[keysCreator][keyType][msg.sender] >= amount, "Insufficient keys");
        keysBalance[keysCreator][keyType][msg.sender] -= amount;
           if(keysBalance[keysCreator][keyType][msg.sender]==0){
            keyHolderCount[keysCreator][keyType]--;
        }
        keysSupply[keysCreator][keyType] = supply - amount;
        nonce++;
        uint timestamp=block.timestamp;
        transactions[nonce] = TransactionDetails(msg.sender, keysCreator, false, amount, price, supply - amount, keyType,timestamp);
        emit Trade(nonce, msg.sender, keysCreator, false, amount, price, supply - amount, keyType,timestamp);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - creatorFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = keysCreator.call{value: creatorFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
     

    }
}