// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import '../interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';
interface IInfluencerTokenFactory {
    function isInfluencerToken(address token) external view returns (bool);
}

contract UniswapV2Factory is IUniswapV2Factory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));
    address public override feeTo;
    address public override feeToSetter;
    address public influencerTokenFactory;
    address public OVDRAddress;
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    mapping(address => bool) public whitelistedTokens;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;

    }
    function setInfluencerTokenFactory(address _influencerTokenFactory,address _OVDRAddress) external {
        require(msg.sender == feeToSetter, 'CustomUniswapV2Factory: FORBIDDEN');
        influencerTokenFactory = _influencerTokenFactory;
        OVDRAddress=_OVDRAddress;
    }
    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }
    function setWhitelistToken(address _tokenAddress, bool whitelist) external{
                require(msg.sender == feeToSetter, 'CustomUniswapV2Factory: FORBIDDEN');
                whitelistedTokens[_tokenAddress]=whitelist;

    }
    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        require(IInfluencerTokenFactory(influencerTokenFactory).isInfluencerToken(token0) || IInfluencerTokenFactory(influencerTokenFactory).isInfluencerToken(token1) || whitelistedTokens[token0] || whitelistedTokens[token1], 'UniswapV2: INVALID_TOKEN');
        require(token0==OVDRAddress || token1==OVDRAddress, 'UniswapV2: INVALID_TOKEN');
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

}
