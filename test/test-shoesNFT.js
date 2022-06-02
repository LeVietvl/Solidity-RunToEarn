const { expect } = require("chai");
const { ethers, network } = require("hardhat");

describe("Run to Earn", function () {
  let [admin, runner1, runner2, runner3, runner4, runner5] = []
  let shoesNFT
  let vietvl
  let reserve
  let amount = ethers.utils.parseEther("100")
  let reserveBalance = ethers.utils.parseEther("1000")
  let address0 = "0x0000000000000000000000000000000000000000"
  beforeEach(async () => {
    [admin, runner1, runner2, runner3, runner4, runner5] = await ethers.getSigners();

    const Vietvl = await ethers.getContractFactory("Vietvl");
    vietvl = await Vietvl.deploy()
    await vietvl.deployed()

    const Reserve = await ethers.getContractFactory("Reserve");
    reserve = await Reserve.deploy(vietvl.address)
    await reserve.deployed()

    const ShoesNFT = await ethers.getContractFactory("ShoesNFT");
    shoesNFT = await ShoesNFT.deploy(vietvl.address, reserve.address, 1)
    await shoesNFT.deployed()

    await vietvl.transfer(reserve.address, ethers.utils.parseEther("10000"))
    await vietvl.transfer(runner1.address, ethers.utils.parseEther("10000"))
    await vietvl.transfer(runner2.address, ethers.utils.parseEther("10000"))
    await vietvl.transfer(runner3.address, ethers.utils.parseEther("10000"))
    await vietvl.transfer(runner4.address, ethers.utils.parseEther("10000"))
    await vietvl.transfer(runner5.address, ethers.utils.parseEther("10000"))
    await vietvl.connect(runner1).approve(shoesNFT.address, ethers.utils.parseEther("10000"))
    await vietvl.connect(runner2).approve(shoesNFT.address, ethers.utils.parseEther("10000"))
    await vietvl.connect(runner3).approve(shoesNFT.address, ethers.utils.parseEther("10000"))
    await vietvl.connect(runner4).approve(shoesNFT.address, ethers.utils.parseEther("10000"))
    await vietvl.connect(runner5).approve(shoesNFT.address, ethers.utils.parseEther("10000"))

    await reserve.setShoesNFTAddress(shoesNFT.address)
    await reserve.setTokenSaleAddress(vietvl.address)
  })

  describe("create ShoesType", function () {
    it("should revert if the caller is not the owner)", async function () {
      await expect(shoesNFT.connect(runner1).createShoesType(5000, 1, 2000)).to.be.revertedWith("Ownable: caller is not the owner")
    });
    it("should create a new shoes type correctly", async function () {
      const shoesTypeTx = await shoesNFT.createShoesType(5000, 1, 2000)
      await expect(shoesTypeTx).to.be.emit(shoesNFT, "ShoesType").withArgs(0, 5000, 1, 2000, false)
    });
  })

  describe("remove shoesType", function () {
    beforeEach(async () => {
      await shoesNFT.createShoesType(5000, 1, 2000)
    })
    it("should revert if ShoesTypeId does not exist", async function () {
      await expect(shoesNFT.removeShoesType(1)).to.be.revertedWith("ShoesNFT: shoesTypeId not exist")
    });
    it("should revert if the ShoesTypeId is aldready removed", async function () {
      await shoesNFT.removeShoesType(0)
      await expect(shoesNFT.removeShoesType(0)).to.be.revertedWith("ShoesNFT: shoesTypeId is offline")
    });
    it("should remove shoesTypeId correctly", async function () {
      await shoesNFT.removeShoesType(0)
      const shoesTypeTx = await shoesNFT.shoesTypes(0)
      expect(await shoesTypeTx.isOffline).to.be.equal(true)
    });
  })

  describe("buy shoes", function () {
    beforeEach(async () => {
      await shoesNFT.createShoesType(5000, 1, 2000)
      await shoesNFT.createShoesType(10000, 1, 8000)
    })
    it("should revert if ShoesTypeId does not exist", async function () {
      await expect(shoesNFT.connect(runner1).buyShoes(2)).to.be.revertedWith("ShoesNFT: shoesTypeId not exist")
    });
    it("should revert if ShoesTypeId is offline", async function () {
      await shoesNFT.removeShoesType(0)
      await expect(shoesNFT.connect(runner1).buyShoes(0)).to.be.revertedWith("ShoesNFT: shoesTypeId is offline")
    });
    it("should buy shoes correctly", async function () {
      await shoesNFT.connect(runner1).buyShoes(0)
      const shoesTx = await shoesNFT.shoes(1)
      expect(shoesTx.shoesTypeId).to.be.equal(0)
      expect(shoesTx.price).to.be.equal(5000)
      expect(shoesTx.tokenEarn).to.be.equal(1)
      expect(shoesTx.duration).to.be.equal(2000)
      expect(shoesTx.isOffline).to.be.equal(false)
      expect(await shoesNFT.ownerOf(1)).to.be.equal(runner1.address)
      expect(await vietvl.balanceOf(runner1.address)).to.be.equal(ethers.utils.parseEther("10000").sub(5000))

      await shoesNFT.connect(runner2).buyShoes(0)
      const shoesTx1 = await shoesNFT.shoes(2)
      expect(shoesTx1.shoesTypeId).to.be.equal(0)
      expect(shoesTx1.price).to.be.equal(5000)
      expect(shoesTx1.tokenEarn).to.be.equal(1)
      expect(shoesTx1.duration).to.be.equal(2000)
      expect(shoesTx1.isOffline).to.be.equal(false)
      expect(await shoesNFT.ownerOf(2)).to.be.equal(runner2.address)
      expect(await vietvl.balanceOf(runner2.address)).to.be.equal(ethers.utils.parseEther("10000").sub(5000))

      await shoesNFT.connect(runner3).buyShoes(1)
      const shoesTx2 = await shoesNFT.shoes(3)
      expect(shoesTx2.shoesTypeId).to.be.equal(1)
      expect(shoesTx2.price).to.be.equal(10000)
      expect(shoesTx2.tokenEarn).to.be.equal(1)
      expect(shoesTx2.duration).to.be.equal(8000)
      expect(shoesTx2.isOffline).to.be.equal(false)
      expect(await shoesNFT.ownerOf(3)).to.be.equal(runner3.address)
      expect(await vietvl.balanceOf(runner3.address)).to.be.equal(ethers.utils.parseEther("10000").sub(10000))
    });
  })
  describe("start run", function () {
    beforeEach(async () => {
      await shoesNFT.createShoesType(5000, 1, 2000)
      await shoesNFT.createShoesType(10000, 1, 8000)
      await shoesNFT.connect(runner1).buyShoes(0)
      await shoesNFT.connect(runner2).buyShoes(0)
      await shoesNFT.connect(runner3).buyShoes(1)
    })
    it("should revert if shoesID does not belong to the caller", async function () {
      await expect(shoesNFT.connect(runner1).startRun(2)).to.be.revertedWith("RTE: Not your shoes")
    });
    it("should revert if duration = 0", async function () {
      await shoesNFT.connect(runner1).startRun(1)
      await shoesNFT.connect(runner1).endRun(1, 2000)
      await expect(shoesNFT.connect(runner1).startRun(1)).to.be.revertedWith("RTE: Your shoes is not safe for run")
    });
    it("should start run correctly", async function () {
      const startRunTx = await shoesNFT.connect(runner1).startRun(1)
      const runTx = await shoesNFT.isStart(runner1.address, 1)
      expect(runTx).to.be.equal(true)

      const blockNum = await ethers.provider.getBlockNumber()
      const block = await ethers.provider.getBlock(blockNum)
      await expect(startRunTx).to.be.emit(shoesNFT, "StartRun").withArgs(block.timestamp, runner1.address, 1)
    });
  })
  describe("end run", function () {
    beforeEach(async () => {
      await shoesNFT.createShoesType(5000, 1, 2000)
      await shoesNFT.createShoesType(10000, 1, 8000)
      await shoesNFT.connect(runner1).buyShoes(0)
      await shoesNFT.connect(runner2).buyShoes(0)
      await shoesNFT.connect(runner3).buyShoes(1)

      await shoesNFT.connect(runner1).startRun(1)
      await shoesNFT.connect(runner2).startRun(2)
    })
    it("should revert if the run has not started yet", async function () {
      await expect(shoesNFT.connect(runner3).endRun(3, 3000)).to.be.revertedWith("RTE: Your run have not started yet")
    });
    it("should end run correctly", async function () {
      const endRunTx = await shoesNFT.connect(runner1).endRun(1, 3000)
      const blockNum = await ethers.provider.getBlockNumber()
      const block = await ethers.provider.getBlock(blockNum)
      await expect(endRunTx).to.be.emit(shoesNFT, "EndRun").withArgs(block.timestamp, runner1.address, 1, 3000)
      const shoesTx = await shoesNFT.shoes(1)
      expect(shoesTx.duration).to.be.equal(0)
      const totalDistanceTx = await shoesNFT.totalDistance(runner1.address, 1)
      const rewarDistanceTx = await shoesNFT.totalDistance(runner1.address, 1)
      const specialRepairDistanceTx = await shoesNFT.totalDistance(runner1.address, 1)
      expect(totalDistanceTx).to.be.equal(2000)
      expect(rewarDistanceTx).to.be.equal(2000)
      expect(specialRepairDistanceTx).to.be.equal(2000)

      const endRunTx1 = await shoesNFT.connect(runner2).endRun(2, 1000)
      const blockNum1 = await ethers.provider.getBlockNumber()
      const block1 = await ethers.provider.getBlock(blockNum1)
      await expect(endRunTx1).to.be.emit(shoesNFT, "EndRun").withArgs(block1.timestamp, runner2.address, 2, 1000)
      const shoesTx1 = await shoesNFT.shoes(2)
      expect(shoesTx1.duration).to.be.equal(1000)
      const totalDistanceTx1 = await shoesNFT.totalDistance(runner2.address, 2)
      const rewarDistanceTx1 = await shoesNFT.totalDistance(runner2.address, 2)
      const specialRepairDistanceTx1 = await shoesNFT.totalDistance(runner2.address, 2)
      expect(totalDistanceTx1).to.be.equal(1000)
      expect(rewarDistanceTx1).to.be.equal(1000)
      expect(specialRepairDistanceTx1).to.be.equal(1000)

      await shoesNFT.connect(runner2).startRun(2)
      const endRunTx2 = await shoesNFT.connect(runner2).endRun(2, 500)
      const blockNum2 = await ethers.provider.getBlockNumber()
      const block2 = await ethers.provider.getBlock(blockNum2)
      await expect(endRunTx2).to.be.emit(shoesNFT, "EndRun").withArgs(block2.timestamp, runner2.address, 2, 500)
      const shoesTx2 = await shoesNFT.shoes(2)
      expect(shoesTx2.duration).to.be.equal(500)
      const totalDistanceTx2 = await shoesNFT.totalDistance(runner2.address, 2)
      const rewarDistanceTx2 = await shoesNFT.totalDistance(runner2.address, 2)
      const specialRepairDistanceTx2 = await shoesNFT.totalDistance(runner2.address, 2)
      expect(totalDistanceTx2).to.be.equal(1500)
      expect(rewarDistanceTx2).to.be.equal(1500)
      expect(specialRepairDistanceTx2).to.be.equal(1500)
    });
  })
  describe("claim reward", function () {
    beforeEach(async () => {
      await shoesNFT.createShoesType(5000, 1, 2000)
      await shoesNFT.createShoesType(10000, 1, 8000)
      await shoesNFT.connect(runner1).buyShoes(0)
      await shoesNFT.connect(runner2).buyShoes(0)
      await shoesNFT.connect(runner3).buyShoes(1)
      await shoesNFT.connect(runner4).buyShoes(1)

      await shoesNFT.connect(runner1).startRun(1)
      await shoesNFT.connect(runner2).startRun(2)
      await shoesNFT.connect(runner3).startRun(3)

      await shoesNFT.connect(runner1).endRun(1, 2000)
      await shoesNFT.connect(runner2).endRun(2, 1500)
      await shoesNFT.connect(runner3).endRun(3, 5000)
    })
    it("should revert if shoesID does not belong to the caller", async function () {
      await expect(shoesNFT.connect(runner1).claimReward(3, 1000)).to.be.revertedWith("RTE: Not your shoes")
    });
    it("should revert if distance = 0", async function () {
      await expect(shoesNFT.connect(runner4).claimReward(4, 1000)).to.be.revertedWith("RTE: No distance")
    });
    it("should revert if distance claim = 0", async function () {
      await expect(shoesNFT.connect(runner1).claimReward(1, 0)).to.be.revertedWith("RTE: Distance claim must be greater than 0")
    });
    it("should revert if distance claim is greater than runner's distance", async function () {
      await expect(shoesNFT.connect(runner1).claimReward(1, 3000)).to.be.revertedWith("RTE: Distance claim must not be greater than distance reward")
    });
    it("should claim reward correctly", async function () {
      const claimTx = await shoesNFT.connect(runner1).claimReward(1, 1000)
      const blockNum = await ethers.provider.getBlockNumber()
      const block = await ethers.provider.getBlock(blockNum)
      await expect(claimTx).to.be.emit(shoesNFT, "ClaimReward").withArgs(runner1.address, 1000, 1000, block.timestamp)
      const totalDistanceTx = await shoesNFT.totalDistance(runner1.address, 1)
      const rewarDistanceTx = await shoesNFT.rewarDistance(runner1.address, 1)
      const specialRepairDistanceTx = await shoesNFT.totalDistance(runner1.address, 1)
      expect(totalDistanceTx).to.be.equal(2000)
      expect(rewarDistanceTx).to.be.equal(1000)
      expect(specialRepairDistanceTx).to.be.equal(2000)
      const totalTokenReward = await shoesNFT.totalTokenReward(runner1.address)
      expect(totalTokenReward).to.be.equal(1000)
      expect(await vietvl.balanceOf(runner1.address)).to.be.equal(ethers.utils.parseEther("10000").add(1000).sub(5000))
    });
  })

  describe("update Required Special Repair Distance ", function () {
    beforeEach(async () => {
      await shoesNFT.createShoesType(5000, 1, 2000)
      await shoesNFT.createShoesType(10000, 1, 8000)
    })
    it("should revert if shoesTypeId does not exist", async function () {
      await expect(shoesNFT.updateRequiredSpecialRepairDistance(2, 10000)).to.be.revertedWith("RTE: shoesTypeId does not exist")
    });
    it("should revert if RequiredSpecialRepairDistance = 0", async function () {
      await expect(shoesNFT.updateRequiredSpecialRepairDistance(0, 0)).to.be.revertedWith("RTE: bad required special repair distance")
    });
    it("should update correctly", async function () {
      await shoesNFT.updateRequiredSpecialRepairDistance(0, 5000)
      const requiredSpecialRepairDistanceTx = await shoesNFT.requiredSpecialRepairDistance(0)
      expect(requiredSpecialRepairDistanceTx).to.be.equal(5000)
    });
  })

  describe("claim Special Repair Promotion", function () {
    beforeEach(async () => {
      await shoesNFT.createShoesType(5000, 1, 2000)
      await shoesNFT.createShoesType(10000, 1, 8000)
      await shoesNFT.connect(runner1).buyShoes(0)
      await shoesNFT.connect(runner2).buyShoes(0)
      await shoesNFT.connect(runner3).buyShoes(1)
      await shoesNFT.updateRequiredSpecialRepairDistance(0, 5000)
    })
    it("should revert if shoesID does not belong to the caller", async function () {
      await expect(shoesNFT.connect(runner1).claimSpecialRepairPromo(2)).to.be.revertedWith("RTE: Not your shoes")
    });
    it("should revert if it is not enough distance to claim", async function () {
      await expect(shoesNFT.connect(runner1).claimSpecialRepairPromo(1)).to.be.revertedWith("RTE: Not enough distance to claim")
    });
    it("should claim correctly", async function () {
      await shoesNFT.connect(runner1).startRun(1)
      await shoesNFT.connect(runner1).endRun(1, 2000)
      await shoesNFT.connect(runner1).repairShoes(1, 2000)
      await shoesNFT.connect(runner1).startRun(1)
      await shoesNFT.connect(runner1).endRun(1, 2000)
      await shoesNFT.connect(runner1).repairShoes(1, 2000)
      await shoesNFT.connect(runner1).startRun(1)
      await shoesNFT.connect(runner1).endRun(1, 2000)
      await shoesNFT.connect(runner1).claimSpecialRepairPromo(1)

      const specialRepairDistanceTx = await shoesNFT.specialRepairDistance(runner1.address, 1)
      expect(specialRepairDistanceTx).to.be.equal(1000)
      const shoesTx = await shoesNFT.shoes(1)
      expect(shoesTx.duration).to.be.equal(2000)
    });
  })

  describe("update Repair Fee", function () {
    it("should revert if repair fee <= 0", async function () {
      await expect(shoesNFT.updateRepairFee(0, 1)).to.be.revertedWith("RTE: bad repair fee")
    });
    it("should update Repair Fee correctly", async function () {
      const repairFeeTx = await shoesNFT.updateRepairFee(5, 1)
      await expect(repairFeeTx).to.be.emit(shoesNFT, "RepairFeeUpdate").withArgs(5, 1)
    });
  })

  describe("repair shoes", function () {
    beforeEach(async () => {
      await shoesNFT.createShoesType(5000, 1, 2000)
      await shoesNFT.createShoesType(10000, 1, 8000)
      await shoesNFT.connect(runner1).buyShoes(0)
      await shoesNFT.connect(runner2).buyShoes(0)
      await shoesNFT.connect(runner1).startRun(1)
      await shoesNFT.connect(runner1).endRun(1, 1500)
      await shoesNFT.updateRepairFee(5, 1)
    })
    it("should revert if shoesID does not belong to the caller", async function () {
      await expect(shoesNFT.connect(runner1).repairShoes(2, 3000)).to.be.revertedWith("RTE: Not your shoes")
    });
    it("should repair correctly when order point > necessary point ", async function () {
      await shoesNFT.connect(runner1).repairShoes(1, 3000)
      const repairCost = 1500 * 5 / 10
      expect(await vietvl.balanceOf(runner1.address)).to.be.equal(ethers.utils.parseEther("10000").sub(5000).sub(repairCost))
      const shoesTx = await shoesNFT.shoes(1)
      expect(shoesTx.duration).to.be.equal(2000)
    });
    it("should repair correctly when order point <= necessary point ", async function () {
      await shoesNFT.connect(runner1).repairShoes(1, 1000)
      const repairCost = 1000 * 5 / 10
      expect(await vietvl.balanceOf(runner1.address)).to.be.equal(ethers.utils.parseEther("10000").sub(5000).sub(repairCost))
      const shoesTx = await shoesNFT.shoes(1)
      expect(shoesTx.duration).to.be.equal(1500)
    });
  })

})
