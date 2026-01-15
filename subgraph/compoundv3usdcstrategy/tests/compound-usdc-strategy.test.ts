import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Bytes, Address } from "@graphprotocol/graph-ts"
import { EmergencyWithdraw } from "../generated/schema"
import { EmergencyWithdraw as EmergencyWithdrawEvent } from "../generated/CompoundUsdcStrategy/CompoundUsdcStrategy"
import { handleEmergencyWithdraw } from "../src/compound-usdc-strategy"
import { createEmergencyWithdrawEvent } from "./compound-usdc-strategy-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#tests-structure

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let timestamp = BigInt.fromI32(234)
    let amount = BigInt.fromI32(234)
    let newEmergencyWithdrawEvent = createEmergencyWithdrawEvent(
      timestamp,
      amount
    )
    handleEmergencyWithdraw(newEmergencyWithdrawEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#write-a-unit-test

  test("EmergencyWithdraw created and stored", () => {
    assert.entityCount("EmergencyWithdraw", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "EmergencyWithdraw",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "timestamp",
      "234"
    )
    assert.fieldEquals(
      "EmergencyWithdraw",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "amount",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#asserts
  })
})
