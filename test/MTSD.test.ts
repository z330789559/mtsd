import { time, loadFixture, } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";


const TREASURY_KEY_SUPPLY = "163000000000000000000000000";
const SEMI_TREASURY_KEY_SUPPLY = "81500000000000000000000000";
const TEAM_KEY_SUPPLY = ethers.BigNumber.from("127000000000000000000000000");
const COMMUNITY_KEY_SUPPLY = ethers.BigNumber.from("250000000000000000000000000");
const PRIVATE_SALE_SUPPLY = ethers.BigNumber.from("60000000000000000000000000");

const SEED_ROUND_SUPPLY = ethers.BigNumber.from("30000000000000000000000000");
describe("MTSD", function () {

  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60 / 15;
    const ONE_MONTH_SECS = 30 * 24 * 60 * 60 / 15;
    const ONE_WEEK = 6 * 24 * 60 * 60 / 15;
    const ONE_GWEI = 1_000_000_000;

    const ONE_ETH = ethers.utils.parseEther("1");
    const fee = 1;
    const lockedAmount = ONE_GWEI;
    const unlockTime = (await time.latestBlock()) + ONE_WEEK;

    const userId = ethers.utils.formatBytes32String("12312321")
    const blankNumber = "6217001180046456133"
    const payToken = "0x0000000000000000000000000000000000000000"
    // 0x06aa  TREASURY_KEY, 0x9b82 TEAM_KEY, 0xe94d  COMMUNITY_KEY, 0x016a  ECOSYSTEM_KEY
    const fistKeys = [0x06aa, 0x9b82, 0xe94d, 0x016a]
    const allKeys = [0x06aa, 0x9b82, 0xe94d, 0x016a, 0x3571, 0x4c53, 0x311d]

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount1, otherAccount2, otherAccount3, otherAccount4, otherAccount5, otherAccount6, otherAccount7, otherAccount8] = await ethers.getSigners();
    console.log("unlockTime", unlockTime)
    const MTSDFactory = await ethers.getContractFactory("MTSD")
    const MTSD = await upgrades.deployProxy(MTSDFactory, [], { initializer: 'initialize' })

    const MTSDToken = MTSD.address
    console.log("erc20", await MTSD.balanceOf(MTSDToken), "address", MTSDToken)
    console.log("total supply", await MTSD.totalSupply())
    console.log("0 地址 金额", await MTSD.balanceOf(payToken))
    console.log("onwer address ", owner.address, "otherAccount1 ", otherAccount1.address, "otherAccount2", otherAccount2.address, "otherAccount3", otherAccount3.address)
    return { unlockTime, lockedAmount, owner, otherAccount1, otherAccount2, otherAccount3, otherAccount4, otherAccount5, otherAccount6, otherAccount7, otherAccount8, userId, blankNumber, fee, payToken, MTSDToken, ONE_ETH, fistKeys, allKeys, ONE_MONTH_SECS };
  }

  describe("Deployment", function () {
    it("Should upgrade contract to v2", async function () {
      const { owner, fee, payToken, otherAccount1, otherAccount2, otherAccount3, MTSDToken } = await loadFixture(deployOneYearLockFixture);

      const MTSDV2Factory = await ethers.getContractFactory("MTSDV2");
      const MTSDV2Contact = await upgrades.deployProxy(MTSDV2Factory, { initializer: 'initialize', kind: 'uups' })
      expect(await MTSDV2Contact.version()).to.equal(2);
    })

    it("default pool address", async () => {

      const { owner, fee, payToken, otherAccount1, otherAccount2, otherAccount3, MTSDToken } = await loadFixture(deployOneYearLockFixture);
      const MTSDFactory = await ethers.getContractFactory("MTSD");
      const MTSD = await upgrades.deployProxy(MTSDFactory, { initializer: 'initialize', kind: 'uups' })
      // expect(await MTSD.version()).to.equal(1);
      expect(await MTSD.poolAddresses(0x06aa, 0)).to.equal(owner.address)
    })

  })

  describe("startNoLinerPool", function () {

    async function init_area() {
      const { owner, fee, payToken, otherAccount1, otherAccount2, otherAccount3, otherAccount4, otherAccount5, otherAccount6, otherAccount7, otherAccount8, MTSDToken, fistKeys, allKeys, unlockTime, ONE_MONTH_SECS } = await loadFixture(deployOneYearLockFixture);
      const MTSDFactory = await ethers.getContractFactory("MTSD");
      const MTSD = await upgrades.deployProxy(MTSDFactory, { initializer: 'initialize', kind: 'uups' })

      console.log("p::", await MTSD.getPoolAddresses(fistKeys[0]))
      const curentBlock = await time.latestBlock()
      await MTSD.startNoLinerPool(curentBlock + 100)

      const startBlock = curentBlock + 100
      // expect(await MTSD.version()).to.equal(1);
      return { owner, fee, payToken, otherAccount1, otherAccount2, otherAccount3, otherAccount4, otherAccount5, otherAccount6, otherAccount7, otherAccount8, MTSDToken, fistKeys, allKeys, unlockTime, MTSD, ONE_MONTH_SECS, startBlock }
    }


    it("Should startNoLinerPool 0x06aa", async function () {
      const { owner, fee, payToken, otherAccount1, otherAccount2, otherAccount3, otherAccount4, otherAccount5, otherAccount6, MTSDToken, fistKeys, allKeys, unlockTime, MTSD, ONE_MONTH_SECS, startBlock } = await loadFixture(init_area);
      const curentBlock = await time.latestBlock()
      for (let i = 0; i < fistKeys.length; i++) {
        const pool = await MTSD.pools(fistKeys[i])
        console.log("pool", pool)
        expect(pool.startBlock.toNumber()).to.equal(startBlock)
      }


      const oldTime = await time.latest()
      console.log("curentBlock", curentBlock, "oldTime", oldTime)
      // time.increase(oldTime + 30 * 24 * 60 * 60)
      for (let i = 0; i < 1000; i++) {
        await ethers.provider.send("evm_mine", []);
      }
      const newCurentBlock = await time.latestBlock()
      console.log("newCurentBlock", newCurentBlock, "new time", await time.latest())
      expect(await MTSD.connect(owner).claimReward(fistKeys)).to.emit(MTSD, 'ClaimReward').withArgs(owner.address, fistKeys, SEMI_TREASURY_KEY_SUPPLY)
      console.log("--pools", await MTSD.pools(fistKeys[0]))


      //owner is TREASURY_KEY 
      expect((await MTSD.balanceOf(owner.address)).toString()).to.equal(SEMI_TREASURY_KEY_SUPPLY)


      for (let i = 0; i < 5; i++) {
        await ethers.provider.send("evm_mine", []);
      }
      const newAfterCurentBlock = await time.latestBlock()
      console.log("otherAccount6 address: ", otherAccount6.address)
      await expect(MTSD.connect(otherAccount6).claimReward(fistKeys)).to.be.emit(MTSD, 'ClaimEvent').withArgs(fistKeys[0], otherAccount6.address, SEMI_TREASURY_KEY_SUPPLY, newAfterCurentBlock + 1)

      expect((await MTSD.balanceOf(otherAccount6.address)).toString()).to.equal(SEMI_TREASURY_KEY_SUPPLY)
      // await(expect( MTSD.connect(otherAccount6).claimReward(fistKeys))).to.be.revertedWith("f2")

      console.log("--2pools", await MTSD.pools(fistKeys[0]))
    })



    it.skip("Should startNoLinerPool 0x9b82", async function () {
      const { owner, fee, payToken, otherAccount1, otherAccount2, otherAccount3, otherAccount4, otherAccount5,
        otherAccount6, otherAccount7, otherAccount8,
        MTSDToken, fistKeys, allKeys, unlockTime, MTSD, ONE_MONTH_SECS, startBlock } = await loadFixture(init_area);
      const curentBlock = await time.latestBlock()


      const oldTime = await time.latest()
      console.log("curentBlock", curentBlock, "oldTime", oldTime)
      const releaseRate = TEAM_KEY_SUPPLY.mul(ethers.BigNumber.from(95 * 15)).div(ethers.BigNumber.from(100 * 60 * 30 * 24 * 60 * 60));
      console.log("releaseRate:", releaseRate.toString()) //11636766975308641975  11636766975308641975


      const releaseAmount = releaseRate.mul(ethers.BigNumber.from(900)).div(ethers.BigNumber.from(2)).add(TEAM_KEY_SUPPLY.mul(ethers.BigNumber.from(5)).div(ethers.BigNumber.from(200)));
      console.log("releaseAmount:", releaseAmount.toString());
      for (let i = 0; i < 1000; i++) {
        await ethers.provider.send("evm_mine", []);
      }
      const newCurentBlock = await time.latestBlock()
      console.log("newCurentBlock1", newCurentBlock, "new time", await time.latest())
      // console.log("--pools1 prev", await MTSD.pools(fistKeys[1]))

      console.log("pending withdraw: ", await MTSD.pending(otherAccount1.address, fistKeys[1]))
      const netxBlock = await time.latestBlock();

      console.log("pending withdraw address1: ", await MTSD.pending(otherAccount1.address, fistKeys[1]))
      expect(await MTSD.pending(otherAccount1.address, fistKeys[1])).to.equal("0");

      const sixMonth = 1 * 24 * 60 * 60 / 15 + 1000;
      console.log("sixMonth", sixMonth)
      for (let i = 0; i < sixMonth; i++) {
        await ethers.provider.send("evm_mine", []);
      }

      const addBlock = await time.latestBlock()
      console.log("newCurentBlock2", addBlock);

      console.log("pending new  withdraw: ", await MTSD.pending(otherAccount1.address, fistKeys[1]))

      console.log("--pools1 after", await MTSD.pools(fistKeys[1]))
      await expect(MTSD.connect(otherAccount1).claimReward(fistKeys)).to.be.emit(MTSD, 'ClaimEvent').withArgs(fistKeys[1], otherAccount1.address, "3186066565393518518517274", addBlock + 1)

      expect((await MTSD.balanceOf(otherAccount1.address))).to.equal("3186066565393518518517274")
      //     //owner is TREASURY_KEY 
      expect((await MTSD.balanceOf(owner.address)).toString()).to.equal(SEMI_TREASURY_KEY_SUPPLY)

      for (let i = 0; i < 5; i++) {
        await ethers.provider.send("evm_mine", []);
      }
      //   console.log("otherAccount6 address: ", otherAccount6.address)
      await expect(MTSD.connect(otherAccount8).claimReward(fistKeys)).to.emit(MTSD, 'ClaimEvent').withArgs(fistKeys[1], otherAccount8.address, "3186101475694444444443196", addBlock + 7)

      expect(await MTSD.balanceOf(otherAccount8.address)).to.equal("3186101475694444444443196")
      console.log("address8 的 amount:", await MTSD.balanceOf(otherAccount8.address))
      //   // await(expect( MTSD.connect(otherAccount7).claimReward(fistKeys))).to.be.revertedWith("f2")

      // console.log("--2pools", await MTSD.pools(fistKeys[1]))
    })


    it.skip("Should startNoLinerPool 0xe94d", async function () {
      const { owner, fee, payToken, otherAccount1, otherAccount2, otherAccount3, otherAccount4, otherAccount5,
        otherAccount6, otherAccount7, otherAccount8,
        MTSDToken, fistKeys, allKeys, unlockTime, MTSD, ONE_MONTH_SECS, startBlock } = await loadFixture(init_area);
      const curentBlock = await time.latestBlock()
      const currentKey = fistKeys[2]

      const oldTime = await time.latest()
      console.log("curentBlock", curentBlock, "oldTime", oldTime)
      const releaseRate = COMMUNITY_KEY_SUPPLY;
      console.log("releaseRate:", releaseRate.toString()) //11636766975308641975  11636766975308641975


      // const releaseAmount = releaseRate.mul(ethers.BigNumber.from(900)).div(ethers.BigNumber.from(2)).add(TEAM_KEY_SUPPLY.mul(ethers.BigNumber.from(5)).div(ethers.BigNumber.from(200)));
      // console.log("releaseAmount:", releaseAmount.toString());
      for (let i = 0; i < 1000; i++) {
        await ethers.provider.send("evm_mine", []);
      }
      const newCurentBlock = await time.latestBlock()
      console.log("newCurentBlock", newCurentBlock, "new time", await time.latest())
      console.log("--pools1 prev", await MTSD.pools(currentKey))

      console.log("pending withdraw0xe94d: ", await MTSD.pending(otherAccount2.address, currentKey))
      const netxBlock = await time.latestBlock();
      console.log("newCurentBlock2", netxBlock);
      await expect(MTSD.connect(otherAccount2).claimReward(fistKeys)).to.be.emit(MTSD, 'ClaimEvent').withArgs(currentKey, otherAccount2.address, COMMUNITY_KEY_SUPPLY.toString(), netxBlock + 1)
      console.log("--pools1 after", await MTSD.pools(currentKey))
      console.log("pending withdraw2: ", await MTSD.pending(otherAccount2.address, currentKey))
      expect((await MTSD.balanceOf(otherAccount2.address))).to.equal(COMMUNITY_KEY_SUPPLY.toString())
      //     //owner is TREASURY_KEY 
      //    expect((await MTSD.balanceOf(owner.address)).toString()).to.equal(SEMI_TREASURY_KEY_SUPPLY)
      await expect(MTSD.connect(otherAccount2).claimReward(fistKeys))
      // console.log("--pools0xe94d after", await MTSD.pools(currentKey))
      expect((await MTSD.balanceOf(otherAccount2.address))).to.equal(COMMUNITY_KEY_SUPPLY.toString())
      //   // await(expect( MTSD.connect(otherAccount7).claimReward(fistKeys))).to.be.revertedWith("f2")
      console.log("otherAccount5 address: ", otherAccount5.address)
      await MTSD.connect(otherAccount5).claimReward(fistKeys)
      expect((await MTSD.balanceOf(otherAccount5.address))).to.equal(0)

      // console.log("--2pools", await MTSD.pools(fistKeys[1]))
    })

    //0x3571
    it("Should startNoLinerPool 0x3571", async function () {
      const { fee, payToken,
        MTSDToken, fistKeys, allKeys, unlockTime, MTSD, ONE_MONTH_SECS, startBlock } = await loadFixture(init_area);

      const [owner, otherAccount1, otherAccount2, otherAccount3, otherAccount4,
        otherAccount5, otherAccount6, otherAccount7, otherAccount8,
        otherAccount9, otherAccount10, otherAccount11
      ] = await ethers.getSigners();
      const curentBlock = await time.latestBlock()
      const currentKey = allKeys[4]

      const releaseRate = PRIVATE_SALE_SUPPLY.mul(ethers.BigNumber.from(80 * 15)).div(ethers.BigNumber.from(100 * 24 * 30 * 24 * 60 * 60));
      console.log("releaseRate:", releaseRate.toString()) //11636766975308641975  11636766975308641975
      const oldTime = await time.latest()
      console.log("curentBlock", curentBlock, "oldTime", oldTime)
      await expect(MTSD.startActive(0x02, curentBlock + 100, [otherAccount5.address, otherAccount9.address, otherAccount10.address]))
        .to.emit(MTSD, 'StartPrivateSale').withArgs(curentBlock + 100, curentBlock + 1, [otherAccount5.address, otherAccount9.address, otherAccount10.address])

      console.log("p::", await MTSD.pools(currentKey))
      const sixMonth = 1 * 24 * 60 * 60 / 15 + 1000;
      console.log("sixMonth", sixMonth)
      for (let i = 0; i < sixMonth; i++) {
        await ethers.provider.send("evm_mine", []);
      }

      console.log("pool address:", await MTSD.poolAddresses(currentKey, 0), await MTSD.poolAddresses(currentKey, 1), await MTSD.poolAddresses(currentKey, 2));
      const netxBlock = await time.latestBlock()
      //release amount 
      await expect(MTSD.connect(otherAccount5).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent')


      // expect((await MTSD.balanceOf(otherAccount5.address)).toString()).to.equal('4003479938271604938271282')

      console.log("pending amount address9:", await MTSD.pending(otherAccount9.address, currentKey), "address9:", otherAccount9.address)
      console.log("current block:", await time.latestBlock(), "next block:", netxBlock + 1)

      await expect(MTSD.connect(otherAccount9).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent')
      // expect((await MTSD.balanceOf(otherAccount9.address)).toString()).to.equal('4003483796296296296295973')

      await expect(MTSD.connect(otherAccount10).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent')
      // expect((await MTSD.balanceOf(otherAccount10.address)).toString()).to.equal('4003487654320987654320664')

      const duration = 1 * 24 * 60 * 60 / 15 ;
      console.log("duration", duration)
      for (let i = 0; i < duration; i++) {
        await ethers.provider.send("evm_mine", []);
      }

      await expect(MTSD.connect(otherAccount5).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent')

      await expect(MTSD.connect(otherAccount9).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent')
      await expect(MTSD.connect(otherAccount10).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent')

      const total_person =PRIVATE_SALE_SUPPLY.div(ethers.BigNumber.from(3))
      console.log("total_person",total_person.toString())
      console.log(await MTSD.balanceOf(otherAccount5.address))
      console.log(await MTSD.balanceOf(otherAccount9.address))
      console.log(await MTSD.balanceOf(otherAccount10.address))
      console.log(await MTSD.pending(otherAccount5.address, currentKey))
    })


    //    //0x4c53
    // it("Should startNoLinerPool 0x4c53", async function () {
    //   const { fee, payToken, 
    //       MTSDToken, fistKeys, allKeys, unlockTime, MTSD, ONE_MONTH_SECS, startBlock } = await loadFixture(init_area);

    //       const [owner, otherAccount1, otherAccount2, otherAccount3, otherAccount4, 
    //         otherAccount5,otherAccount6, otherAccount7, otherAccount8,
    //         otherAccount9,otherAccount10,otherAccount11,otherAccount12,otherAccount13
    //       ]=await ethers.getSigners();
    //   const curentBlock = await time.latestBlock()
    //  const currentKey=allKeys[4]

    //  const releaseRate =SEED_ROUND_SUPPLY.mul(ethers.BigNumber.from(80 * 15)).div(ethers.BigNumber.from(100 * 24 * 30 * 24 * 60 * 60));
    //   console.log("releaseRate:", releaseRate.toString()) //11636766975308641975  11636766975308641975
    //   const oldTime = await time.latest()
    //   console.log("curentBlock", curentBlock, "oldTime", oldTime)
    //    await expect(MTSD.startActive(0x01, curentBlock + 100,[otherAccount5.address,otherAccount9.address,otherAccount10.address]))
    //   .to.emit(MTSD, 'StartPrivateSale').withArgs(curentBlock + 100, curentBlock +1,[otherAccount5.address,otherAccount9.address,otherAccount10.address])

    //   console.log("p::", await MTSD.pools(currentKey))
    //   for (let i = 0; i < 1000; i++) {
    //     await ethers.provider.send("evm_mine", []);
    //   }

    //     console.log("pool address:",await MTSD.poolAddresses(currentKey,0),await MTSD.poolAddresses(currentKey,1),await MTSD.poolAddresses(currentKey,2));
    //     const netxBlock = await time.latestBlock()
    //   //release amount 
    //   await expect(MTSD.connect(otherAccount5).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent').withArgs(currentKey, otherAccount5.address, "4003479938271604938271282", netxBlock + 1)


    //      expect((await MTSD.balanceOf(otherAccount5.address)).toString()).to.equal('4003479938271604938271282')

    //      console.log("pending amount address6:",await MTSD.pending(otherAccount9.address,currentKey),"address6:",otherAccount9.address)
    //      console.log("current block:",await time.latestBlock(),"next block:",netxBlock + 1)

    //   await expect(MTSD.connect(otherAccount9).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent').withArgs(currentKey, otherAccount9.address, "4003483796296296296295973", netxBlock + 2)
    //   expect((await MTSD.balanceOf(otherAccount9.address)).toString()).to.equal('4003483796296296296295973')

    //   await expect(MTSD.connect(otherAccount10).claimReward(allKeys)).to.be.emit(MTSD, 'ClaimEvent').withArgs(currentKey, otherAccount10.address, "4003487654320987654320664", netxBlock + 3)
    //   expect((await MTSD.balanceOf(otherAccount10.address)).toString()).to.equal('4003487654320987654320664')

    // })
  })

})
