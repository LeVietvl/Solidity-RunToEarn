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
    Counters.Counter private _shoesTypeIdCount;
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
        uint256 shoesTypeId,
        uint256 price,
        bytes32 indexed name,
        uint256 tokenEarn,
        uint256 duration,
        bool isOffline
    );

    struct ShoesInfo {
        uint256 shoesTypeId;
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
            _shoesTypeIdCount.current(),
            _price,
            _name,
            _tokenEarn,
            _duration,
            false
        );
        shoesTypes.push(shoesType);
        _shoesTypeIdCount.increment();

        emit ShoesType(
            _shoesTypeIdCount.current(),
            _price,
            _name,
            _tokenEarn,
            _duration,
            false
        );
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
        shoe.shoesTypeId = shoesType.shoesTypeId;
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
    event ClaimReward(
        address indexed runner,
        uint256 tokenReward,
        uint256 distanceReward,
        uint256 time
    );

    mapping(address => mapping(uint256 => uint256)) public totalDistance;
    mapping(address => mapping(uint256 => uint256)) public rewarDistance;
    mapping(address => mapping(uint256 => uint256))
        public specialRepairDistance;
    mapping(address => uint256) public totalTokenReward;
    mapping(address => mapping(uint256 => bool)) public isStart;

    function startRun(uint256 _shoesId) external {
        require(ownerOf(_shoesId) == _msgSender(), "RTE: Not your shoes");
        require(
            shoes[_shoesId].duration > 0,
            "RTE: Your shoes is not safe for run"
        );
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
            totalDistance[_msgSender()][_shoesId] += shoe.duration;
            rewarDistance[_msgSender()][_shoesId] += shoe.duration;
            specialRepairDistance[_msgSender()][_shoesId] += shoe.duration;
            shoe.duration = 0;
        } else {
            shoes[_shoesId].duration -= _distance;
            totalDistance[_msgSender()][_shoesId] += _distance;
            rewarDistance[_msgSender()][_shoesId] += _distance;
            specialRepairDistance[_msgSender()][_shoesId] += _distance;
        }
        emit EndRun(block.timestamp, _msgSender(), _shoesId, _distance);
    }

    function claimReward(uint256 _shoesId, uint256 _distanceClaim) external {
        require(ownerOf(_shoesId) == _msgSender(), "RTE: Not your shoes");
        require(rewarDistance[_msgSender()][_shoesId] > 0, "RTE: No distance");
        require(
            _distanceClaim > 0,
            "RTE: Distance claim must be greater than 0"
        );
        require(
            _distanceClaim <= rewarDistance[_msgSender()][_shoesId],
            "RTE: Distance claim must not be greater than distance reward"
        );

        ShoesInfo storage shoe = shoes[_shoesId];
        uint256 tokenReward = shoe.tokenEarn * _distanceClaim;
        rewarDistance[_msgSender()][_shoesId] -= _distanceClaim;
        totalTokenReward[_msgSender()] += tokenReward;
        reserve.distributeToken(_msgSender(), tokenReward);

        emit ClaimReward(
            _msgSender(),
            tokenReward,
            _distanceClaim,
            block.timestamp
        );
    }

    event RepairFeeUpdate(uint256 repairFee);
    event RequiredSpecialRepairDistanceUpdate(
        uint256 shoesId,
        uint256 repairFee
    );
    uint256 public repairFee;
    uint256 public requiredSpecialRepairDistance;

    function updateRepairFee(uint256 _repairFee) external onlyOwner {
        require(_repairFee >= 0, "RTE: bad repair fee");
        repairFee = _repairFee;

        emit RepairFeeUpdate(_repairFee);
    }

    function updateRequiredSpecialRepairDistance(
        uint256 _shoesId,
        uint256 _requiredSpecialRepairDistance
    ) external onlyOwner {
        require(
            _requiredSpecialRepairDistance > 0,
            "RTE: bad required special repair distance"
        );
        requiredSpecialRepairDistance = _requiredSpecialRepairDistance;

        emit RequiredSpecialRepairDistanceUpdate(
            _shoesId,
            _requiredSpecialRepairDistance
        );
    }

    function claimSpecialRepairPromo(uint256 _shoesId) external {
        require(ownerOf(_shoesId) == _msgSender(), "RTE: Not your shoes");
        require(
            specialRepairDistance[_msgSender()][_shoesId] >=
                requiredSpecialRepairDistance,
            "RTE: Not enough distance to claim"
        );
        specialRepairDistance[_msgSender()][
            _shoesId
        ] -= requiredSpecialRepairDistance;
        shoes[_shoesId].duration = shoesTypes[shoes[_shoesId].shoesTypeId]
            .duration;
    }

    function repairShoe(uint256 _shoesId, uint256 _durationPoint) external {
        if (
            _durationPoint + shoes[_shoesId].duration >
            shoesTypes[shoes[_shoesId].shoesTypeId].duration
        ) {
            uint256 repairDuration = shoesTypes[shoes[_shoesId].shoesTypeId]
                .duration - shoes[_shoesId].duration;
            uint256 repairCost = repairDuration * repairFee;
            tokenVIE.transferFrom(_msgSender(), reserveAddress, repairCost);
            shoes[_shoesId].duration = shoesTypes[shoes[_shoesId].shoesTypeId]
                .duration;
        } else {
            uint256 repairCost = _durationPoint * repairFee;
            tokenVIE.transferFrom(_msgSender(), reserveAddress, repairCost);
            shoes[_shoesId].duration += _durationPoint;
        }
    }
}
