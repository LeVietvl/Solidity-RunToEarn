// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Reserve/Reserve.sol";

contract ShoesNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _shoesIdCount;
    IERC20 public immutable tokenVIE;
    Reserve public immutable reserve;
    address public reserveAddress;

    constructor(address _tokenVIE, address _reserveAddress)
        ERC721("ShoesNFT", "Shoes")
    {
        tokenVIE = IERC20(_tokenVIE);
        reserve = Reserve(_reserveAddress);
        reserveAddress = _reserveAddress;
    }

    event ShoesType(
        uint256 price,
        bytes32 indexed name,
        uint256 tokenEarn,
        uint256 duration,
        bool isOffline
    );

    struct ShoesInfo {
        uint256 price;
        bytes32 name;
        uint256 tokenEarn;
        uint256 duration;
        bool isOffline;
    }

    ShoesInfo[] public shoesTypes;
    mapping(uint256 => ShoesInfo) public shoes;

    function createShoesType(
        uint256 _price,
        bytes32 _name,
        uint256 _tokenEarn,
        uint256 _duration
    ) external onlyOwner {
        ShoesInfo memory shoesType = ShoesInfo(
            _price,
            _name,
            _tokenEarn,
            _duration,
            false
        );
        shoesTypes.push(shoesType);

        emit ShoesType(_price, _name, _tokenEarn, _duration, false);
    }

    function removeShoesType(uint256 _shoesTypeId) external onlyOwner {
        require(
            _shoesTypeId < shoesTypes.length,
            "ShoesNFT: shoesTypeId not exist"
        );
        ShoesInfo storage shoesType = shoesTypes[_shoesTypeId];
        require(
            shoesType.isOffline == false,
            "ShoesNFT: shoesTypeId is offline"
        );
        shoesType.isOffline = true;
    }

    function buyShoes(uint256 _shoesTypeId) external {
        require(
            _shoesTypeId < shoesTypes.length,
            "ShoesNFT: shoesTypeId not exist"
        );
        ShoesInfo storage shoesType = shoesTypes[_shoesTypeId];
        require(
            shoesType.isOffline == false,
            "ShoesNFT: shoesTypeId is offline"
        );

        tokenVIE.transferFrom(_msgSender(), reserveAddress, shoesType.price);
        _shoesIdCount.increment();
        uint256 _shoesId = _shoesIdCount.current();
        _mint(_msgSender(), _shoesId);
        ShoesInfo storage shoe = shoes[_shoesId];
        shoe.price = shoesType.price;
        shoe.name = shoesType.name;
        shoe.tokenEarn = shoesType.tokenEarn;
        shoe.duration = shoesType.duration;
        shoe.isOffline = shoesType.isOffline;
    }

    event StartRun(uint256 startTime, address indexed runner, uint256 shoesId);
    event EndRun(
        uint256 endTime,
        address indexed runner,
        uint256 shoesId,
        uint256 distance
    );

    mapping(address => mapping(uint256 => uint256)) public distance;
    mapping(address => mapping(uint256 => bool)) public isStart;

    function startRun(uint256 _shoesId) external {
        require(ownerOf(_shoesId) == _msgSender(), "RTE: Not your shoes");
        require(
            shoes[_shoesId].duration > 0,
            "RTE: Your shoes is not safe for run"
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
        ShoesInfo storage shoe = shoes[_shoesId];
        if (_distance > shoe.duration) {
            distance[_msgSender()][_shoesId] += shoe.duration;
            shoe.duration = 0;
        } else {
            shoes[_shoesId].duration -= _distance;
            distance[_msgSender()][_shoesId] += _distance;
        }
        emit EndRun(block.timestamp, _msgSender(), _shoesId, _distance);
    }

    function claimReward(uint256 _shoesId) external {
        require(ownerOf(_shoesId) == _msgSender(), "RTE: Not your shoes");
    }
}
