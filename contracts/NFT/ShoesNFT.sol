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
        bool isOffline
    );

    struct ShoesInfo {
        uint256 price;
        bytes32 name;
        uint256 tokenEarn;
        bool isOffline;
    }

    ShoesInfo[] public shoesTypes;
    mapping(uint256 => ShoesInfo) public shoes;

    function createShoesType(
        uint256 _price,
        bytes32 _name,
        uint256 _tokenEarn
    ) external onlyOwner {
        ShoesInfo memory shoesType = ShoesInfo(
            _price,
            _name,
            _tokenEarn,
            false
        );
        shoesTypes.push(shoesType);

        emit ShoesType(_price, _name, _tokenEarn, false);
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

        tokenVIE.transferFrom(
            _msgSender(),
            address(reserveAddress),
            shoesType.price
        );
        _shoesIdCount.increment();
        uint256 _shoesId = _shoesIdCount.current();
    }
}
