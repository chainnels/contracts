// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CreatorKey is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        address influencer,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        require(initialSupply > 0, "Initial supply must be greater than 0");
        transferOwnership(influencer);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
