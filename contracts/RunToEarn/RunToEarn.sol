// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NFT/ShoesNFT.sol";
import "../Reserve/Reserve.sol";

contract RuntoEarn is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _accountIdCount;
    IERC20 public immutable tokenVIE;
    IERC721 public immutable shoesNFT;
    Reserve public immutable reserve;
    address public reserveAddress;

    event StartRun(uint256 startTime, address indexed runner, uint256 shoesId);
    event EndRun(uint256 endTime, address indexed runner, uint256 shoesId);

    constructor(
        address _tokenVIE,
        address _shoesNFT,
        address _reserveAddress
    ) {
        tokenVIE = IERC20(_tokenVIE);
        shoesNFT = IERC721(_shoesNFT);
        reserve = Reserve(_reserveAddress);
        reserveAddress = _reserveAddress;
    }

    mapping(address => mapping(uint256 => uint256)) public distance;
    mapping(address => mapping(uint256 => bool)) public isStart;

    function startRun(uint256 _shoesId) external {
        require(
            shoesNFT.ownerOf(_shoesId) == _msgSender(),
            "RTE: Not your shoes"
        );
        distance[_msgSender()][_shoesId] = 0;
        isStart[_msgSender()][_shoesId] = true;

        emit StartRun(block.timestamp, _msgSender(), _shoesId);
    }

    function endRun(uint256 _shoesId, uint256 _distance) external {
        require(
            isStart[_msgSender()][_shoesId],
            "RTE: Your run have not started yet"
        );
        isStart[_msgSender()][_shoesId] = false;
        if(_distance > )
        distance[_msgSender()][_shoesId] += _distance;
        

        emit EndRun(block.timestamp, _msgSender(), _shoesId);
    }

    function claimReward(uint256 _shoesId) external {
        require(
            shoesNFT.ownerOf(_shoesId) == _msgSender(),
            "RTE: Not your shoes"
        );
        
    }
}
