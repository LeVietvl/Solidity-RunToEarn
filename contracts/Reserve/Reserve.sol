// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Staking reserve is a contract that holds tokens from staking actions and allows
//  the staking contract to take the amount to interest their profit

contract Reserve is Ownable {
    IERC20 public tokenVIE;
    address public shoesNFTAddress;
    address public gemNFTAddress;
    address public tokenSaleAddress;

    constructor(address _tokenVIE) {
        tokenVIE = IERC20(_tokenVIE);
    }

    function setShoesNFTAddress(address _shoesNFTAddress) external onlyOwner {
        shoesNFTAddress = _shoesNFTAddress;
    }

    function setGemNFTAddress(address _gemNFTAddress) external onlyOwner {
        gemNFTAddress = _gemNFTAddress;
    }

    function setTokenSaleAddress(address _tokenSaleAddress) external onlyOwner {
        tokenSaleAddress = _tokenSaleAddress;
    }

    function distributeToken(address _recipient, uint256 _amount) public {
        require(
            msg.sender == shoesNFTAddress ||
                msg.sender == gemNFTAddress ||
                msg.sender == tokenSaleAddress
        );
        require(
            _amount <= tokenVIE.balanceOf(address(this)),
            "Reserve: Not enough token"
        );
        tokenVIE.transfer(_recipient, _amount);
    }
}
