// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Reserve/Reserve.sol";

contract TokenSale is Ownable {
    uint256 public investorMinCap = 0.02 ether;
    uint256 public investorHardCap = 10 ether;
    uint256 public rate = 10;
    address public feeRecipient;
    uint256 public feeDecimal;
    uint256 public feeRate;

    event FeeRateUpdated(uint256 feeDecimal, uint256 feeRate);

    mapping(address => uint256) public contributions;
    IERC20 public tokenVIE;
    Reserve public immutable reserve;
    address public reserveAddress;

    constructor(
        address _tokenAddress,
        address _reserveAddress,
        uint256 feeDecimal_,
        uint256 feeRate_
    ) {
        tokenVIE = IERC20(_tokenAddress);
        reserve = Reserve(_reserveAddress);
        reserveAddress = _reserveAddress;
        _updateFeeRate(feeDecimal_, feeRate_);
    }

    //update rate

    function updateRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function _updateFeeRate(uint256 feeDecimal_, uint256 feeRate_) internal {
        require(feeRate_ < 10**(feeDecimal_ + 2), "TokenSale: bad fee rate");
        feeDecimal = feeDecimal_;
        feeRate = feeRate_;
    }

    function updateFeeRate(uint256 feeDecimal_, uint256 feeRate_)
        external
        onlyOwner
    {
        _updateFeeRate(feeDecimal_, feeRate_);
        emit FeeRateUpdated(feeDecimal_, feeRate_);
    }

    function _calculateFee(uint256 amount_) private view returns (uint256) {
        if (feeRate == 0) {
            return 0;
        }
        return (feeRate * amount_) / 10**(feeDecimal + 2);
    }

    function buy() public payable {
        uint256 amountToken = msg.value * rate;
        require(amountToken > investorMinCap, "TokenSale: Not reach min cap");
        require(
            contributions[msg.sender] + amountToken < investorHardCap,
            "TokenSale: exceed hard cap"
        );
        require(
            tokenVIE.balanceOf(reserveAddress) >= amountToken,
            "TokenSale: exceed token balance"
        );

        reserve.distributeToken(_msgSender(), amountToken);
    }

    function sell(uint256 amountToken) public payable {
        require(
            contributions[msg.sender] >= amountToken,
            "TokenSale: Your contribution do not have enough token"
        );
        uint256 fee = _calculateFee(amountToken);
        uint256 ethAmount = (amountToken - fee) / rate;

        contributions[msg.sender] -= amountToken;
        tokenVIE.transferFrom(_msgSender(), reserveAddress, amountToken);
        payable(msg.sender).transfer(ethAmount);
    }
}
