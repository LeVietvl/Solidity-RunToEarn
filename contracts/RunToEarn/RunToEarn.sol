// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NFT/ShoesNFT.sol";

contract RunToEarn is Ownable, ShoesNFT {
    using Counters for Counters.Counter;
    Counters.Counter private _shoesTypeIdCount;
    Counters.Counter private _shoesIdCount;

    IERC20 public immutable tokenVIE;
    IERC721 public immutable shoesNFT;
    IERC721 public immutable gemNFT;

    event ShoesType(
        uint256 indexed shoesTypeId,
        uint256 price,
        bytes32 indexed name,
        uint256 tokenEarn,
        bool isOffline
    );

    constructor(
        address _tokenVIE,
        address _shoesNFT,
        address _gemNFT
    ) {
        tokenVIE = IERC20(_tokenVIE);
        shoesNFT = IERC721(_shoesNFT);
        gemNFT = IERC721(_gemNFT);
    }

    // Declare shoes variable.
    // tokenEarn: the number of tokens earned per 10 km.
    struct ShoesInfo {
        uint256 price;
        bytes32 name;
        uint256 tokenEarn;
        bool isOffline;
    }

    mapping(uint256 => ShoesInfo) public shoesTypes;
    mapping(uint256 => mapping(uint256 => ShoesInfo)) public shoes;

    function createShoesType(
        uint256 _price,
        bytes32 _name,
        uint256 _tokenEarn
    ) external onlyOwner {
        _shoesTypeIdCount.increment();
        uint256 _shoesTypeId = _shoesTypeIdCount.current();
        ShoesInfo storage shoesType = shoesTypes[_shoesTypeId];
        shoesType.price = _price;
        shoesType.name = _name;
        shoesType.tokenEarn = _tokenEarn;

        emit ShoesType(_shoesTypeId, _price, _name, _tokenEarn, false);
    }

    function removeShoesType(uint256 _shoesTypeId) external onlyOwner {
        require(
            _shoesTypeId <= _shoesTypeIdCount.current(),
            "RTE: shoesTypeId not exist"
        );
        ShoesInfo storage shoesType = shoesTypes[_shoesTypeId];
        require(shoesType.isOffline == false, "RTE: shoesTypeId is offline");
        shoesType.isOffline = true;
    }

    function buyShoes(uint256 _shoesTypeId) external {
        require(
            _shoesTypeId <= _shoesTypeIdCount.current(),
            "RTE: shoesTypeId not exist"
        );
        ShoesInfo storage shoesType = shoesTypes[_shoesTypeId];
        require(shoesType.isOffline == false, "RTE: shoesTypeId is offline");
        _shoesIdCount.increment();
        uint256 _shoesId = _shoesIdCount.current();
        shoesNFT.mint(_msgSender(), _shoesId);
    }
}
