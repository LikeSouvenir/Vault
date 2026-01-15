import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Bytes, Address } from "@graphprotocol/graph-ts"
import {
  EmergencyWithdraw,
  Pull,
  Push,
  Report,
  RoleAdminChanged,
  RoleGranted,
  RoleRevoked,
  StrategyPaused,
  StrategyUnpaused
} from "../generated/CompoundUsdcStrategy/CompoundUsdcStrategy"

export function createEmergencyWithdrawEvent(
  timestamp: BigInt,
  amount: BigInt
): EmergencyWithdraw {
  let emergencyWithdrawEvent = changetype<EmergencyWithdraw>(newMockEvent())

  emergencyWithdrawEvent.parameters = new Array()

  emergencyWithdrawEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )
  emergencyWithdrawEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return emergencyWithdrawEvent
}

export function createPullEvent(assetPull: BigInt): Pull {
  let pullEvent = changetype<Pull>(newMockEvent())

  pullEvent.parameters = new Array()

  pullEvent.parameters.push(
    new ethereum.EventParam(
      "assetPull",
      ethereum.Value.fromUnsignedBigInt(assetPull)
    )
  )

  return pullEvent
}

export function createPushEvent(assetPush: BigInt): Push {
  let pushEvent = changetype<Push>(newMockEvent())

  pushEvent.parameters = new Array()

  pushEvent.parameters.push(
    new ethereum.EventParam(
      "assetPush",
      ethereum.Value.fromUnsignedBigInt(assetPush)
    )
  )

  return pushEvent
}

export function createReportEvent(
  time: BigInt,
  profit: BigInt,
  loss: BigInt
): Report {
  let reportEvent = changetype<Report>(newMockEvent())

  reportEvent.parameters = new Array()

  reportEvent.parameters.push(
    new ethereum.EventParam("time", ethereum.Value.fromUnsignedBigInt(time))
  )
  reportEvent.parameters.push(
    new ethereum.EventParam("profit", ethereum.Value.fromUnsignedBigInt(profit))
  )
  reportEvent.parameters.push(
    new ethereum.EventParam("loss", ethereum.Value.fromUnsignedBigInt(loss))
  )

  return reportEvent
}

export function createRoleAdminChangedEvent(
  role: Bytes,
  previousAdminRole: Bytes,
  newAdminRole: Bytes
): RoleAdminChanged {
  let roleAdminChangedEvent = changetype<RoleAdminChanged>(newMockEvent())

  roleAdminChangedEvent.parameters = new Array()

  roleAdminChangedEvent.parameters.push(
    new ethereum.EventParam("role", ethereum.Value.fromFixedBytes(role))
  )
  roleAdminChangedEvent.parameters.push(
    new ethereum.EventParam(
      "previousAdminRole",
      ethereum.Value.fromFixedBytes(previousAdminRole)
    )
  )
  roleAdminChangedEvent.parameters.push(
    new ethereum.EventParam(
      "newAdminRole",
      ethereum.Value.fromFixedBytes(newAdminRole)
    )
  )

  return roleAdminChangedEvent
}

export function createRoleGrantedEvent(
  role: Bytes,
  account: Address,
  sender: Address
): RoleGranted {
  let roleGrantedEvent = changetype<RoleGranted>(newMockEvent())

  roleGrantedEvent.parameters = new Array()

  roleGrantedEvent.parameters.push(
    new ethereum.EventParam("role", ethereum.Value.fromFixedBytes(role))
  )
  roleGrantedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  roleGrantedEvent.parameters.push(
    new ethereum.EventParam("sender", ethereum.Value.fromAddress(sender))
  )

  return roleGrantedEvent
}

export function createRoleRevokedEvent(
  role: Bytes,
  account: Address,
  sender: Address
): RoleRevoked {
  let roleRevokedEvent = changetype<RoleRevoked>(newMockEvent())

  roleRevokedEvent.parameters = new Array()

  roleRevokedEvent.parameters.push(
    new ethereum.EventParam("role", ethereum.Value.fromFixedBytes(role))
  )
  roleRevokedEvent.parameters.push(
    new ethereum.EventParam("account", ethereum.Value.fromAddress(account))
  )
  roleRevokedEvent.parameters.push(
    new ethereum.EventParam("sender", ethereum.Value.fromAddress(sender))
  )

  return roleRevokedEvent
}

export function createStrategyPausedEvent(timestamp: BigInt): StrategyPaused {
  let strategyPausedEvent = changetype<StrategyPaused>(newMockEvent())

  strategyPausedEvent.parameters = new Array()

  strategyPausedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return strategyPausedEvent
}

export function createStrategyUnpausedEvent(
  timestamp: BigInt
): StrategyUnpaused {
  let strategyUnpausedEvent = changetype<StrategyUnpaused>(newMockEvent())

  strategyUnpausedEvent.parameters = new Array()

  strategyUnpausedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )

  return strategyUnpausedEvent
}
