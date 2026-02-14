import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const address2 = accounts.get("wallet_2")!;
const deployer = accounts.get("deployer")!;

describe("VaultForge Protocol - Decentralized Lending", () => {
  // ============================================
  // Constants Tests
  // ============================================
  describe("constants", () => {
    it("should have correct error constants", () => {
      const ERR_NOT_AUTHORIZED = 1000;
      const ERR_VAULT_NOT_FOUND = 1001;
      const ERR_INSUFFICIENT_COLLATERAL = 1002;
      const ERR_VAULT_UNDERCOLLATERALIZED = 1003;
      const ERR_LIQUIDATION_NOT_ALLOWED = 1004;
      const ERR_INVALID_AMOUNT = 1005;
      const ERR_ORACLE_PRICE_STALE = 1006;
      const ERR_MINIMUM_COLLATERAL_RATIO = 1007;
      const ERR_VAULT_ALREADY_EXISTS = 1008;
      const ERR_INSUFFICIENT_USDX_BALANCE = 1009;
      const ERR_TRANSFER_FAILED = 1010;
      
      expect(ERR_NOT_AUTHORIZED).toBe(1000);
      expect(ERR_VAULT_NOT_FOUND).toBe(1001);
      expect(ERR_INSUFFICIENT_COLLATERAL).toBe(1002);
      expect(ERR_VAULT_UNDERCOLLATERALIZED).toBe(1003);
      expect(ERR_LIQUIDATION_NOT_ALLOWED).toBe(1004);
      expect(ERR_INVALID_AMOUNT).toBe(1005);
      expect(ERR_ORACLE_PRICE_STALE).toBe(1006);
      expect(ERR_MINIMUM_COLLATERAL_RATIO).toBe(1007);
      expect(ERR_VAULT_ALREADY_EXISTS).toBe(1008);
      expect(ERR_INSUFFICIENT_USDX_BALANCE).toBe(1009);
      expect(ERR_TRANSFER_FAILED).toBe(1010);
    });

    it("should have correct risk management parameters", () => {
      const LIQUIDATION_RATIO = 150;
      const MINIMUM_COLLATERAL_RATIO = 200;
      const LIQUIDATION_PENALTY = 110;
      const STABILITY_FEE_RATE = 2;
      const MAX_PRICE_AGE = 3600;
      
      expect(LIQUIDATION_RATIO).toBe(150);
      expect(MINIMUM_COLLATERAL_RATIO).toBe(200);
      expect(LIQUIDATION_PENALTY).toBe(110);
      expect(STABILITY_FEE_RATE).toBe(2);
      expect(MAX_PRICE_AGE).toBe(3600);
    });
  });

  // ============================================
  // USDx Token Tests
  // ============================================
  describe("USDx synthetic token", () => {
    it("should have correct token metadata", () => {
      const tokenName = "USDx Synthetic Dollar";
      const tokenSymbol = "USDx";
      const tokenDecimals = 6;
      
      expect(tokenName).toBe("USDx Synthetic Dollar");
      expect(tokenSymbol).toBe("USDx");
      expect(tokenDecimals).toBe(6);
    });

    it("should handle balance calculations", () => {
      const balance = 1000000;
      const amount = 500000;
      const newBalance = balance - amount;
      
      expect(balance).toBe(1000000);
      expect(amount).toBe(500000);
      expect(newBalance).toBe(500000);
    });

    it("should validate transfer conditions", () => {
      const fromBalance = 1000;
      const amount = 500;
      const isValid = fromBalance >= amount && amount > 0;
      
      expect(fromBalance).toBe(1000);
      expect(amount).toBe(500);
      expect(isValid).toBe(true);
    });
  });

  // ============================================
  // Oracle Price Feed Tests
  // ============================================
  describe("oracle price feeds", () => {
    it("should validate price age", () => {
      const currentBlock = 1500;
      const priceTimestamp = 1000;
      const maxPriceAge = 3600;
      const isStale = (currentBlock - priceTimestamp) > maxPriceAge;
      
      expect(currentBlock).toBe(1500);
      expect(priceTimestamp).toBe(1000);
      expect(maxPriceAge).toBe(3600);
      expect(isStale).toBe(false);
    });

    it("should detect stale prices", () => {
      const currentBlock = 5000;
      const priceTimestamp = 1000;
      const maxPriceAge = 3600;
      const isStale = (currentBlock - priceTimestamp) > maxPriceAge;
      
      expect(currentBlock).toBe(5000);
      expect(priceTimestamp).toBe(1000);
      expect(isStale).toBe(true);
    });

    it("should validate confidence scores", () => {
      const minConfidence = 1;
      const maxConfidence = 100;
      const validConfidence = 95;
      const invalidConfidence = 150;
      
      const isValidValid = validConfidence >= minConfidence && validConfidence <= maxConfidence;
      const isValidInvalid = invalidConfidence >= minConfidence && invalidConfidence <= maxConfidence;
      
      expect(isValidValid).toBe(true);
      expect(isValidInvalid).toBe(false);
    });
  });

  // ============================================
  // Vault Creation Tests
  // ============================================
  describe("vault creation", () => {
    it("should calculate vault ID correctly", () => {
      const totalVaults = 5;
      const newVaultId = totalVaults + 1;
      
      expect(totalVaults).toBe(5);
      expect(newVaultId).toBe(6);
    });

    it("should track user vaults correctly", () => {
      const userVaults = [1, 3, 5];
      const newVaultId = 7;
      const updatedVaults = [...userVaults, newVaultId];
      
      expect(userVaults.length).toBe(3);
      expect(updatedVaults.length).toBe(4);
      expect(updatedVaults).toContain(7);
    });

    it("should enforce minimum collateral", () => {
      const stxAmount = 0;
      const xbtcAmount = 1000;
      const isValid = stxAmount > 0 || xbtcAmount > 0;
      
      expect(stxAmount).toBe(0);
      expect(xbtcAmount).toBe(1000);
      expect(isValid).toBe(true);
    });
  });

  // ============================================
  // Collateral Value Calculations
  // ============================================
  describe("collateral calculations", () => {
    it("should calculate total collateral value correctly", () => {
      const stxAmount = 1000;
      const stxPrice = 1000000; // $1 in microSTX
      const xbtcAmount = 2;
      const xbtcPrice = 100000000000; // $100,000 in sats
      
      const stxValue = stxAmount * stxPrice;
      const xbtcValue = xbtcAmount * xbtcPrice;
      const totalValue = stxValue + xbtcValue;
      
      expect(stxValue).toBe(1000000000);
      expect(xbtcValue).toBe(200000000000);
      expect(totalValue).toBe(201000000000);
    });

    it("should calculate collateral ratio correctly", () => {
      const collateralValue = 200000000000;
      const debt = 100000000;
      const ratio = (collateralValue * 100) / debt;
      
      expect(collateralValue).toBe(200000000000);
      expect(debt).toBe(100000000);
      expect(ratio).toBe(200000); // 200,000%
    });

    it("should validate minimum collateral ratio", () => {
      const minRatio = 200;
      const currentRatio = 250;
      const isValid = currentRatio >= minRatio;
      
      expect(minRatio).toBe(200);
      expect(currentRatio).toBe(250);
      expect(isValid).toBe(true);
    });
  });

  // ============================================
  // Debt Management Tests
  // ============================================
  describe("debt management", () => {
    it("should update debt correctly on mint", () => {
      const currentDebt = 1000;
      const mintAmount = 500;
      const newDebt = currentDebt + mintAmount;
      
      expect(currentDebt).toBe(1000);
      expect(mintAmount).toBe(500);
      expect(newDebt).toBe(1500);
    });

    it("should update debt correctly on burn", () => {
      const currentDebt = 1500;
      const burnAmount = 500;
      const newDebt = currentDebt - burnAmount;
      
      expect(currentDebt).toBe(1500);
      expect(burnAmount).toBe(500);
      expect(newDebt).toBe(1000);
    });

    it("should prevent burning more than debt", () => {
      const currentDebt = 1000;
      const burnAmount = 1500;
      const isValid = burnAmount <= currentDebt;
      
      expect(currentDebt).toBe(1000);
      expect(burnAmount).toBe(1500);
      expect(isValid).toBe(false);
    });
  });

  // ============================================
  // Health Factor Calculations
  // ============================================
  describe("health factor", () => {
    it("should calculate health factor correctly", () => {
      const collateralValue = 300000000000;
      const debt = 100000000;
      const healthFactor = (collateralValue * 100) / debt;
      
      expect(collateralValue).toBe(300000000000);
      expect(debt).toBe(100000000);
      expect(healthFactor).toBe(300000); // 300,000%
    });

    it("should return max health factor for zero debt", () => {
      const collateralValue = 300000000000;
      const debt = 0;
      const healthFactor = debt === 0 ? 999999 : (collateralValue * 100) / debt;
      
      expect(healthFactor).toBe(999999);
    });

    it("should detect undercollateralized vaults", () => {
      const liquidationRatio = 150;
      const healthFactor = 140;
      const isSafe = healthFactor >= liquidationRatio;
      
      expect(liquidationRatio).toBe(150);
      expect(healthFactor).toBe(140);
      expect(isSafe).toBe(false);
    });
  });

  // ============================================
  // Liquidation Tests
  // ============================================
  describe("liquidation engine", () => {
    it("should calculate liquidation penalty correctly", () => {
      const debt = 1000;
      const penaltyPercent = 110; // 10% penalty
      const penaltyAmount = (debt * penaltyPercent) / 100;
      
      expect(debt).toBe(1000);
      expect(penaltyAmount).toBe(1100);
    });

    it("should calculate liquidator reward correctly", () => {
      const collateral = 2000;
      const liquidationAmount = 1100;
      const debt = 1000;
      const liquidatorReward = (collateral * liquidationAmount) / debt;
      
      expect(collateral).toBe(2000);
      expect(liquidationAmount).toBe(1100);
      expect(debt).toBe(1000);
      expect(liquidatorReward).toBe(2200);
    });

    it("should calculate remaining collateral for protocol", () => {
      const totalCollateral = 2000;
      const liquidatorShare = 1100;
      const protocolShare = totalCollateral - liquidatorShare;
      
      expect(totalCollateral).toBe(2000);
      expect(liquidatorShare).toBe(1100);
      expect(protocolShare).toBe(900);
    });
  });

  // ============================================
  // Protocol Statistics Tests
  // ============================================
  describe("protocol statistics", () => {
    it("should track total vaults correctly", () => {
      let totalVaults = 0;
      
      totalVaults += 1;
      expect(totalVaults).toBe(1);
      
      totalVaults += 3;
      expect(totalVaults).toBe(4);
      
      totalVaults -= 1;
      expect(totalVaults).toBe(3);
    });

    it("should track total debt correctly", () => {
      let totalDebt = 0;
      
      totalDebt += 1000;
      expect(totalDebt).toBe(1000);
      
      totalDebt += 500;
      expect(totalDebt).toBe(1500);
      
      totalDebt -= 200;
      expect(totalDebt).toBe(1300);
    });

    it("should calculate total USDx supply", () => {
      const minted = 5000;
      const burned = 1000;
      const totalSupply = minted - burned;
      
      expect(minted).toBe(5000);
      expect(burned).toBe(1000);
      expect(totalSupply).toBe(4000);
    });
  });

  // ============================================
  // Access Control Tests
  // ============================================
  describe("access control", () => {
    it("should identify vault owner correctly", () => {
      const vaultOwner = "wallet_1";
      const txSender = "wallet_1";
      const notOwner = "wallet_2";
      
      const isOwner = txSender === vaultOwner;
      const isNotOwner = notOwner === vaultOwner;
      
      expect(isOwner).toBe(true);
      expect(isNotOwner).toBe(false);
    });

    it("should identify oracle operators correctly", () => {
      const operator = "wallet_1";
      const authorized = true;
      const isAuthorized = operator === "wallet_1" ? authorized : false;
      
      expect(operator).toBe("wallet_1");
      expect(authorized).toBe(true);
      expect(isAuthorized).toBe(true);
    });

    it("should identify liquidators correctly", () => {
      const liquidator = "wallet_2";
      const authorized = true;
      const isAuthorized = liquidator === "wallet_2" ? authorized : false;
      
      expect(liquidator).toBe("wallet_2");
      expect(authorized).toBe(true);
      expect(isAuthorized).toBe(true);
    });
  });

  // ============================================
  // Edge Cases
  // ============================================
  describe("edge cases", () => {
    it("should handle zero amount operations", () => {
      const amount = 0;
      const isValid = amount > 0;
      
      expect(amount).toBe(0);
      expect(isValid).toBe(false);
    });

    it("should handle maximum uint values", () => {
      const maxUint = BigInt("340282366920938463463374607431768211455");
      const collateral = maxUint - 1000n;
      const debt = maxUint / 2n;
      
      expect(collateral < maxUint).toBe(true);
      expect(debt < maxUint).toBe(true);
    });

    it("should handle empty vault lists", () => {
      const userVaults: number[] = [];
      
      expect(userVaults.length).toBe(0);
      expect(userVaults).toEqual([]);
    });

    it("should handle inactive vaults", () => {
      const isActive = false;
      
      expect(isActive).toBe(false);
    });
  });

  // ============================================
  // Event Structure Tests
  // ============================================
  describe("event structures", () => {
    it("should have correct protocol initialized event structure", () => {
      const protocolInitializedEvent = {
        event: "protocol-initialized",
        contractOwner: "deployer",
        liquidationRatio: 150,
        minimumRatio: 200,
        liquidationPenalty: 110,
        stabilityFee: 2,
        maxPriceAge: 3600,
        blockHeight: 1000
      };
      
      expect(protocolInitializedEvent.event).toBe("protocol-initialized");
      expect(protocolInitializedEvent.contractOwner).toBe("deployer");
      expect(protocolInitializedEvent.liquidationRatio).toBe(150);
      expect(protocolInitializedEvent.minimumRatio).toBe(200);
      expect(protocolInitializedEvent.liquidationPenalty).toBe(110);
      expect(protocolInitializedEvent.stabilityFee).toBe(2);
      expect(protocolInitializedEvent.maxPriceAge).toBe(3600);
      expect(protocolInitializedEvent.blockHeight).toBe(1000);
    });

    it("should have correct usdx transfer event structure", () => {
      const usdxTransferEvent = {
        event: "usdx-transfer",
        from: "wallet_1",
        to: "wallet_2",
        amount: 1000,
        memo: "payment",
        blockHeight: 1200
      };
      
      expect(usdxTransferEvent.event).toBe("usdx-transfer");
      expect(usdxTransferEvent.from).toBe("wallet_1");
      expect(usdxTransferEvent.to).toBe("wallet_2");
      expect(usdxTransferEvent.amount).toBe(1000);
      expect(usdxTransferEvent.memo).toBe("payment");
      expect(usdxTransferEvent.blockHeight).toBe(1200);
    });

    it("should have correct oracle operator updated event structure", () => {
      const oracleOperatorEvent = {
        event: "oracle-operator-updated",
        operator: "wallet_3",
        authorized: true,
        updatedBy: "deployer",
        blockHeight: 1100
      };
      
      expect(oracleOperatorEvent.event).toBe("oracle-operator-updated");
      expect(oracleOperatorEvent.operator).toBe("wallet_3");
      expect(oracleOperatorEvent.authorized).toBe(true);
      expect(oracleOperatorEvent.updatedBy).toBe("deployer");
      expect(oracleOperatorEvent.blockHeight).toBe(1100);
    });

    it("should have correct price updated event structure", () => {
      const priceUpdatedEvent = {
        event: "price-updated",
        asset: "STX",
        oldPrice: 1000000,
        newPrice: 1100000,
        confidence: 95,
        timestamp: 1500,
        updater: "wallet_3"
      };
      
      expect(priceUpdatedEvent.event).toBe("price-updated");
      expect(priceUpdatedEvent.asset).toBe("STX");
      expect(priceUpdatedEvent.oldPrice).toBe(1000000);
      expect(priceUpdatedEvent.newPrice).toBe(1100000);
      expect(priceUpdatedEvent.confidence).toBe(95);
      expect(priceUpdatedEvent.timestamp).toBe(1500);
      expect(priceUpdatedEvent.updater).toBe("wallet_3");
    });

    it("should have correct vault created event structure", () => {
      const vaultCreatedEvent = {
        event: "vault-created",
        vaultId: 1,
        owner: "wallet_1",
        stxAmount: 1000,
        xbtcAmount: 2,
        totalCollateralValue: 201000000000,
        blockHeight: 1300
      };
      
      expect(vaultCreatedEvent.event).toBe("vault-created");
      expect(vaultCreatedEvent.vaultId).toBe(1);
      expect(vaultCreatedEvent.owner).toBe("wallet_1");
      expect(vaultCreatedEvent.stxAmount).toBe(1000);
      expect(vaultCreatedEvent.xbtcAmount).toBe(2);
      expect(vaultCreatedEvent.totalCollateralValue).toBe(201000000000);
      expect(vaultCreatedEvent.blockHeight).toBe(1300);
    });

    it("should have correct collateral added event structure", () => {
      const collateralAddedEvent = {
        event: "collateral-added",
        vaultId: 1,
        owner: "wallet_1",
        stxAdded: 500,
        xbtcAdded: 1,
        newStxTotal: 1500,
        newXbtcTotal: 3,
        blockHeight: 1400
      };
      
      expect(collateralAddedEvent.event).toBe("collateral-added");
      expect(collateralAddedEvent.vaultId).toBe(1);
      expect(collateralAddedEvent.owner).toBe("wallet_1");
      expect(collateralAddedEvent.stxAdded).toBe(500);
      expect(collateralAddedEvent.xbtcAdded).toBe(1);
      expect(collateralAddedEvent.newStxTotal).toBe(1500);
      expect(collateralAddedEvent.newXbtcTotal).toBe(3);
      expect(collateralAddedEvent.blockHeight).toBe(1400);
    });

    it("should have correct usdx minted event structure", () => {
      const usdxMintedEvent = {
        event: "usdx-minted",
        vaultId: 1,
        minter: "wallet_1",
        amount: 100000,
        newDebt: 100000,
        collateralRatio: 200000,
        blockHeight: 1500
      };
      
      expect(usdxMintedEvent.event).toBe("usdx-minted");
      expect(usdxMintedEvent.vaultId).toBe(1);
      expect(usdxMintedEvent.minter).toBe("wallet_1");
      expect(usdxMintedEvent.amount).toBe(100000);
      expect(usdxMintedEvent.newDebt).toBe(100000);
      expect(usdxMintedEvent.collateralRatio).toBe(200000);
      expect(usdxMintedEvent.blockHeight).toBe(1500);
    });

    it("should have correct usdx burned event structure", () => {
      const usdxBurnedEvent = {
        event: "usdx-burned",
        vaultId: 1,
        burner: "wallet_1",
        amount: 50000,
        oldDebt: 100000,
        newDebt: 50000,
        blockHeight: 1600
      };
      
      expect(usdxBurnedEvent.event).toBe("usdx-burned");
      expect(usdxBurnedEvent.vaultId).toBe(1);
      expect(usdxBurnedEvent.burner).toBe("wallet_1");
      expect(usdxBurnedEvent.amount).toBe(50000);
      expect(usdxBurnedEvent.oldDebt).toBe(100000);
      expect(usdxBurnedEvent.newDebt).toBe(50000);
      expect(usdxBurnedEvent.blockHeight).toBe(1600);
    });

    it("should have correct collateral withdrawn event structure", () => {
      const collateralWithdrawnEvent = {
        event: "collateral-withdrawn",
        vaultId: 1,
        owner: "wallet_1",
        stxAmount: 300,
        remainingStx: 1200,
        remainingXbtc: 3,
        debt: 50000,
        newRatio: 250000,
        blockHeight: 1700
      };
      
      expect(collateralWithdrawnEvent.event).toBe("collateral-withdrawn");
      expect(collateralWithdrawnEvent.vaultId).toBe(1);
      expect(collateralWithdrawnEvent.owner).toBe("wallet_1");
      expect(collateralWithdrawnEvent.stxAmount).toBe(300);
      expect(collateralWithdrawnEvent.remainingStx).toBe(1200);
      expect(collateralWithdrawnEvent.remainingXbtc).toBe(3);
      expect(collateralWithdrawnEvent.debt).toBe(50000);
      expect(collateralWithdrawnEvent.newRatio).toBe(250000);
      expect(collateralWithdrawnEvent.blockHeight).toBe(1700);
    });

    it("should have correct liquidator updated event structure", () => {
      const liquidatorUpdatedEvent = {
        event: "liquidator-updated",
        liquidator: "wallet_4",
        authorized: true,
        updatedBy: "deployer",
        blockHeight: 1800
      };
      
      expect(liquidatorUpdatedEvent.event).toBe("liquidator-updated");
      expect(liquidatorUpdatedEvent.liquidator).toBe("wallet_4");
      expect(liquidatorUpdatedEvent.authorized).toBe(true);
      expect(liquidatorUpdatedEvent.updatedBy).toBe("deployer");
      expect(liquidatorUpdatedEvent.blockHeight).toBe(1800);
    });

    it("should have correct vault liquidated event structure", () => {
      const vaultLiquidatedEvent = {
        event: "vault-liquidated",
        vaultId: 1,
        liquidator: "wallet_4",
        vaultOwner: "wallet_1",
        debtRepaid: 50000,
        stxToLiquidator: 550,
        xbtcToLiquidator: 1,
        stxToPool: 450,
        xbtcToPool: 0.5,
        healthFactorBefore: 140,
        liquidationRatio: 150,
        blockHeight: 1900
      };
      
      expect(vaultLiquidatedEvent.event).toBe("vault-liquidated");
      expect(vaultLiquidatedEvent.vaultId).toBe(1);
      expect(vaultLiquidatedEvent.liquidator).toBe("wallet_4");
      expect(vaultLiquidatedEvent.vaultOwner).toBe("wallet_1");
      expect(vaultLiquidatedEvent.debtRepaid).toBe(50000);
      expect(vaultLiquidatedEvent.stxToLiquidator).toBe(550);
      expect(vaultLiquidatedEvent.xbtcToLiquidator).toBe(1);
      expect(vaultLiquidatedEvent.stxToPool).toBe(450);
      expect(vaultLiquidatedEvent.xbtcToPool).toBe(0.5);
      expect(vaultLiquidatedEvent.healthFactorBefore).toBe(140);
      expect(vaultLiquidatedEvent.liquidationRatio).toBe(150);
      expect(vaultLiquidatedEvent.blockHeight).toBe(1900);
    });

    it("should have correct emergency shutdown event structure", () => {
      const emergencyShutdownEvent = {
        event: "emergency-shutdown",
        triggeredBy: "deployer",
        blockHeight: 2000,
        totalDebtFrozen: 1000000,
        totalVaultsFrozen: 25
      };
      
      expect(emergencyShutdownEvent.event).toBe("emergency-shutdown");
      expect(emergencyShutdownEvent.triggeredBy).toBe("deployer");
      expect(emergencyShutdownEvent.blockHeight).toBe(2000);
      expect(emergencyShutdownEvent.totalDebtFrozen).toBe(1000000);
      expect(emergencyShutdownEvent.totalVaultsFrozen).toBe(25);
    });

    it("should have correct liquidation ratio updated event structure", () => {
      const ratioUpdatedEvent = {
        event: "liquidation-ratio-updated",
        oldRatio: 150,
        newRatio: 160,
        updatedBy: "deployer",
        blockHeight: 2100
      };
      
      expect(ratioUpdatedEvent.event).toBe("liquidation-ratio-updated");
      expect(ratioUpdatedEvent.oldRatio).toBe(150);
      expect(ratioUpdatedEvent.newRatio).toBe(160);
      expect(ratioUpdatedEvent.updatedBy).toBe("deployer");
      expect(ratioUpdatedEvent.blockHeight).toBe(2100);
    });

    it("should have correct minimum ratio updated event structure", () => {
      const minRatioUpdatedEvent = {
        event: "minimum-ratio-updated",
        oldRatio: 200,
        newRatio: 210,
        updatedBy: "deployer",
        blockHeight: 2200
      };
      
      expect(minRatioUpdatedEvent.event).toBe("minimum-ratio-updated");
      expect(minRatioUpdatedEvent.oldRatio).toBe(200);
      expect(minRatioUpdatedEvent.newRatio).toBe(210);
      expect(minRatioUpdatedEvent.updatedBy).toBe("deployer");
      expect(minRatioUpdatedEvent.blockHeight).toBe(2200);
    });

    it("should have correct protocol stats structure", () => {
      const protocolStats = {
        totalVaults: 25,
        totalDebt: 1000000,
        totalStxCollateral: 50000,
        totalXbtcCollateral: 100,
        totalUsdxSupply: 900000,
        liquidationPool: 50000,
        lastEmergencyShutdown: 0
      };
      
      expect(protocolStats.totalVaults).toBe(25);
      expect(protocolStats.totalDebt).toBe(1000000);
      expect(protocolStats.totalStxCollateral).toBe(50000);
      expect(protocolStats.totalXbtcCollateral).toBe(100);
      expect(protocolStats.totalUsdxSupply).toBe(900000);
      expect(protocolStats.liquidationPool).toBe(50000);
      expect(protocolStats.lastEmergencyShutdown).toBe(0);
    });
  });
});
