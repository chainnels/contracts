// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./InfluencerTokenFactory.sol";

contract Membership is Initializable,UUPSUpgradeable, OwnableUpgradeable {
    struct Subscription {
        uint256 endDate;
    }

    mapping(address => mapping(address => Subscription)) public userSubscriptions;
    mapping(address => address[]) public userMembershipTokens;
    mapping(address => uint256) public subscriptionPrices;

    InfluencerTokenFactory private influencerTokenFactory;
    IUniswapV2Router02 private uniswapV2Router;
    address private usdcToken;

    event Subscribed(
        address indexed user,
        address indexed influencer,
        address indexed token,
        uint256 months,
        uint256 totalCost
    );
 function initialize(
        address _influencerTokenFactory,
        address _uniswapV2Router,
        address _usdcToken
    ) public initializer {
        __Ownable_init();
         __UUPSUpgradeable_init();
        influencerTokenFactory = InfluencerTokenFactory(_influencerTokenFactory);
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
                usdcToken = _usdcToken;
    }
  
    function _authorizeUpgrade(address) internal override onlyOwner {}

     function setSubscriptionPrice(address token, uint256 pricePerMonth) external {
        require(token != address(0), "Token address cannot be zero");
        address influencer = influencerTokenFactory.getInfluencerByToken(token);
        require(influencer == msg.sender, "Only the influencer can set the price");
        subscriptionPrices[token] = pricePerMonth;
    }

   
    function subscribe(
        address token,
        uint256 months
    ) external {
        require(token != address(0), "Token address cannot be zero");
        require(months > 0, "Minimum subscription is 1 month");
        address influencer = influencerTokenFactory.getInfluencerByToken(token);
        require(influencer != address(0), "Invalid influencer token");
        uint256 pricePerMonth = subscriptionPrices[token];
        require(pricePerMonth > 0, "Subscription price not set");

        uint256 totalCost = pricePerMonth * months;
        require(totalCost / pricePerMonth == months, "Total cost calculation overflow");

        uint256 influencerShare = (totalCost * 90) / 100;
        uint256 contractCreatorShare = totalCost - influencerShare;

        IERC20(token).transferFrom(msg.sender, influencer, influencerShare);
        IERC20(token).transferFrom(msg.sender, address(this), contractCreatorShare);

        // Swap contractCreatorShare to USDC
        _swapTokensForUSDC(token, contractCreatorShare);

        Subscription storage subscription = userSubscriptions[msg.sender][token];

        uint256 currentEndDate = subscription.endDate > block.timestamp
            ? subscription.endDate
            : block.timestamp;
        subscription.endDate = currentEndDate + (months * 30 days);

        userMembershipTokens[msg.sender].push(token);
        emit Subscribed(msg.sender, influencer, token, months, totalCost);
    }

    function _swapTokensForUSDC(address token, uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = usdcToken;

        IERC20(token).approve(address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0, // Accept any amount of USDC
            path,
            address(this),
            block.timestamp + 300 // Deadline 5 minutes from now
        );
    }

    function getSubscriptionEndDate(address user, address token)
        external
        view
        returns (uint256)
    {
        return userSubscriptions[user][token].endDate;
    }

    function getUserMemberships(
        address user,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (address[] memory) {
        require(startIndex < endIndex, "startIndex must be less than endIndex");
        require(endIndex <= userMembershipTokens[user].length, "endIndex out of range");

        uint256 length = endIndex - startIndex;
        address[] memory memberships = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            memberships[i] = userMembershipTokens[user][startIndex + i];
        }

        return memberships;
    }

    function getUserMembershipCount(address user) external view returns (uint256) {
        return userMembershipTokens[user].length;
    }

}

