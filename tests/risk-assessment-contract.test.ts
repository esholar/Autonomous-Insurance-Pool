import { describe, it, expect, beforeEach } from "vitest"

describe("Risk Assessment Contract", () => {
  let mockStorage: Map<string, any>
  let riskNonce: number
  
  beforeEach(() => {
    mockStorage = new Map()
    riskNonce = 0
  })
  
  const mockContractCall = (method: string, args: any[], sender: string) => {
    switch (method) {
      case "add-risk-profile":
        const [riskType, basePremium, riskFactor] = args
        riskNonce++
        mockStorage.set(`risk-${riskNonce}`, {
          "risk-type": riskType,
          "base-premium": basePremium,
          "risk-factor": riskFactor,
        })
        return { success: true, value: riskNonce }
      case "get-risk-profile":
        return { success: true, value: mockStorage.get(`risk-${args[0]}`) }
      case "update-risk-profile":
        const [riskId, newBasePremium, newRiskFactor] = args
        const risk = mockStorage.get(`risk-${riskId}`)
        if (!risk) return { success: false, error: "Risk profile not found" }
        risk["base-premium"] = newBasePremium
        risk["risk-factor"] = newRiskFactor
        mockStorage.set(`risk-${riskId}`, risk)
        return { success: true }
      case "calculate-premium":
        const [calcRiskId, coverageAmount] = args
        const calcRisk = mockStorage.get(`risk-${calcRiskId}`)
        if (!calcRisk) return { success: false, error: "Risk profile not found" }
        const premium = (calcRisk["base-premium"] * coverageAmount * calcRisk["risk-factor"]) / 10000
        return { success: true, value: premium }
      default:
        return { success: false, error: "Method not found" }
    }
  }
  
  it("should add a risk profile", () => {
    const result = mockContractCall("add-risk-profile", ["fire", 100, 150], "CONTRACT_OWNER")
    expect(result.success).toBe(true)
    expect(result.value).toBe(1)
  })
  
  it("should get a risk profile", () => {
    mockContractCall("add-risk-profile", ["fire", 100, 150], "CONTRACT_OWNER")
    const result = mockContractCall("get-risk-profile", [1], "anyone")
    expect(result.success).toBe(true)
    expect(result.value["risk-type"]).toBe("fire")
  })
  
  it("should update a risk profile", () => {
    mockContractCall("add-risk-profile", ["fire", 100, 150], "CONTRACT_OWNER")
    const result = mockContractCall("update-risk-profile", [1, 120, 180], "CONTRACT_OWNER")
    expect(result.success).toBe(true)
  })
  
  it("should calculate premium correctly", () => {
    mockContractCall("add-risk-profile", ["fire", 100, 150], "CONTRACT_OWNER")
    const result = mockContractCall("calculate-premium", [1, 1000], "anyone")
    expect(result.success).toBe(true)
    expect(result.value).toBe(15000) // (100 * 1000 * 150) / 10000
  })
})

