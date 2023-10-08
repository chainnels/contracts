// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./InfluencerToken.sol";
//reentrancy guard
contract InfluencerTokenFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    mapping(address => address[]) public influencerTokens;
    mapping(address => address) public tokenInfluencer;
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapV2Factory;

    event TokenCreated(
        address indexed influencer,
        address indexed token,
        string name,
        string symbol
    );
    // constructor() {
    //     _disableInitializers();
    // }
    function initialize(
        address routerAddress,
        address factoryAddress
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Factory = IUniswapV2Factory(factoryAddress);
    }

    function createToken(
    string calldata name,
    string calldata symbol,
    uint256 initialSupply
) external {
    InfluencerToken token = new InfluencerToken(name, symbol, msg.sender, initialSupply);
    influencerTokens[msg.sender].push(address(token));
    tokenInfluencer[address(token)] = msg.sender;
    emit TokenCreated(msg.sender, address(token), name, symbol);
}
    function isInfluencerToken(address token) external view returns (bool) {
    return tokenInfluencer[token] != address(0);
    }

    function getInfluencerByToken(address token) external view returns (address) {
        return tokenInfluencer[token];
    }

    function getTokensByInfluencer(address influencer) external view returns (address[] memory) {
        return influencerTokens[influencer];
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
