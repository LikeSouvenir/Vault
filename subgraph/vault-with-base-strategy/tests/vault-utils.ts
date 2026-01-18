import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  Approval,
  Deposit,
  Reported,
  RoleAdminChanged,
  RoleGranted,
  RoleRevoked,
  StrategyAdded,
  StrategyMigrated,
  StrategyRemoved,
  Transfer,
  UpdateManagementFee,
  UpdateManagementRecipient,
  UpdatePerformanceFee,
  UpdateStrategyInfo,
  UpdateStrategySharePercent,
  UpdateWithdrawalQueue,
  Withdraw
} from "../generated/Vault/Vault"

export function createApprovalEvent(
  owner: Address,
  spender: Address,
  value: BigInt
): Approval {
  let approvalEvent = changetype<Approval>(newMockEvent())

  approvalEvent.parameters = new Array()

  approvalEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam("spender", ethereum.Value.fromAddress(spender))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam("value", ethereum.Value.fromUnsignedBigInt(value))
  )

  return approvalEvent
}

export function createDepositEvent(
  sender: Address,
  owner: Address,
  assets: BigInt,
  shares: BigInt
): Deposit {
  let depositEvent = changetype<Deposit>(newMockEvent())

  depositEvent.parameters = new Array()

  depositEvent.parameters.push(
    new ethereum.EventParam("sender", ethereum.Value.fromAddress(sender))
  )
  depositEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  depositEvent.parameters.push(
    new ethereum.EventParam("assets", ethereum.Value.fromUnsignedBigInt(assets))
  )
  depositEvent.parameters.push(
    new ethereum.EventParam("shares", ethereum.Value.fromUnsignedBigInt(shares))
  )

  return depositEvent
}

export function createReportedEvent(
  profit: BigInt,
  loss: BigInt,
  managementFees: BigInt,
  performanceFees: BigInt
): Reported {
  let reportedEvent = changetype<Reported>(newMockEvent())

  reportedEvent.parameters = new Array()

  reportedEvent.parameters.push(
    new ethereum.EventParam("profit", ethereum.Value.fromUnsignedBigInt(profit))
  )
  reportedEvent.parameters.push(
    new ethereum.EventParam("loss", ethereum.Value.fromUnsignedBigInt(loss))
  )
  reportedEvent.parameters.push(
    new ethereum.EventParam(
      "managementFees",
      ethereum.Value.fromUnsignedBigInt(managementFees)
    )
  )
  reportedEvent.parameters.push(
    new ethereum.EventParam(
      "performanceFees",
      ethereum.Value.fromUnsignedBigInt(performanceFees)
    )
  )

  return reportedEvent
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

export function createStrategyAddedEvent(strategy: Address): StrategyAdded {
  let strategyAddedEvent = changetype<StrategyAdded>(newMockEvent())

  strategyAddedEvent.parameters = new Array()

  strategyAddedEvent.parameters.push(
    new ethereum.EventParam("strategy", ethereum.Value.fromAddress(strategy))
  )

  return strategyAddedEvent
}

export function createStrategyMigratedEvent(
  oldVersion: Address,
  newVersion: Address
): StrategyMigrated {
  let strategyMigratedEvent = changetype<StrategyMigrated>(newMockEvent())

  strategyMigratedEvent.parameters = new Array()

  strategyMigratedEvent.parameters.push(
    new ethereum.EventParam(
      "oldVersion",
      ethereum.Value.fromAddress(oldVersion)
    )
  )
  strategyMigratedEvent.parameters.push(
    new ethereum.EventParam(
      "newVersion",
      ethereum.Value.fromAddress(newVersion)
    )
  )

  return strategyMigratedEvent
}

export function createStrategyRemovedEvent(
  strategy: Address,
  totalAssets: BigInt
): StrategyRemoved {
  let strategyRemovedEvent = changetype<StrategyRemoved>(newMockEvent())

  strategyRemovedEvent.parameters = new Array()

  strategyRemovedEvent.parameters.push(
    new ethereum.EventParam("strategy", ethereum.Value.fromAddress(strategy))
  )
  strategyRemovedEvent.parameters.push(
    new ethereum.EventParam(
      "totalAssets",
      ethereum.Value.fromUnsignedBigInt(totalAssets)
    )
  )

  return strategyRemovedEvent
}

export function createTransferEvent(
  from: Address,
  to: Address,
  value: BigInt
): Transfer {
  let transferEvent = changetype<Transfer>(newMockEvent())

  transferEvent.parameters = new Array()

  transferEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam("value", ethereum.Value.fromUnsignedBigInt(value))
  )

  return transferEvent
}

export function createUpdateManagementFeeEvent(fee: i32): UpdateManagementFee {
  let updateManagementFeeEvent = changetype<UpdateManagementFee>(newMockEvent())

  updateManagementFeeEvent.parameters = new Array()

  updateManagementFeeEvent.parameters.push(
    new ethereum.EventParam(
      "fee",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(fee))
    )
  )

  return updateManagementFeeEvent
}

export function createUpdateManagementRecipientEvent(
  recipient: Address
): UpdateManagementRecipient {
  let updateManagementRecipientEvent =
    changetype<UpdateManagementRecipient>(newMockEvent())

  updateManagementRecipientEvent.parameters = new Array()

  updateManagementRecipientEvent.parameters.push(
    new ethereum.EventParam("recipient", ethereum.Value.fromAddress(recipient))
  )

  return updateManagementRecipientEvent
}

export function createUpdatePerformanceFeeEvent(
  strategy: Address,
  newFee: i32
): UpdatePerformanceFee {
  let updatePerformanceFeeEvent =
    changetype<UpdatePerformanceFee>(newMockEvent())

  updatePerformanceFeeEvent.parameters = new Array()

  updatePerformanceFeeEvent.parameters.push(
    new ethereum.EventParam("strategy", ethereum.Value.fromAddress(strategy))
  )
  updatePerformanceFeeEvent.parameters.push(
    new ethereum.EventParam(
      "newFee",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(newFee))
    )
  )

  return updatePerformanceFeeEvent
}

export function createUpdateStrategyInfoEvent(
  strategy: Address,
  newBalance: BigInt
): UpdateStrategyInfo {
  let updateStrategyInfoEvent = changetype<UpdateStrategyInfo>(newMockEvent())

  updateStrategyInfoEvent.parameters = new Array()

  updateStrategyInfoEvent.parameters.push(
    new ethereum.EventParam("strategy", ethereum.Value.fromAddress(strategy))
  )
  updateStrategyInfoEvent.parameters.push(
    new ethereum.EventParam(
      "newBalance",
      ethereum.Value.fromUnsignedBigInt(newBalance)
    )
  )

  return updateStrategyInfoEvent
}

export function createUpdateStrategySharePercentEvent(
  strategy: Address,
  newPercent: BigInt
): UpdateStrategySharePercent {
  let updateStrategySharePercentEvent =
    changetype<UpdateStrategySharePercent>(newMockEvent())

  updateStrategySharePercentEvent.parameters = new Array()

  updateStrategySharePercentEvent.parameters.push(
    new ethereum.EventParam("strategy", ethereum.Value.fromAddress(strategy))
  )
  updateStrategySharePercentEvent.parameters.push(
    new ethereum.EventParam(
      "newPercent",
      ethereum.Value.fromUnsignedBigInt(newPercent)
    )
  )

  return updateStrategySharePercentEvent
}

export function createUpdateWithdrawalQueueEvent(
  queue: Array<Address>
): UpdateWithdrawalQueue {
  let updateWithdrawalQueueEvent =
    changetype<UpdateWithdrawalQueue>(newMockEvent())

  updateWithdrawalQueueEvent.parameters = new Array()

  updateWithdrawalQueueEvent.parameters.push(
    new ethereum.EventParam("queue", ethereum.Value.fromAddressArray(queue))
  )

  return updateWithdrawalQueueEvent
}

export function createWithdrawEvent(
  sender: Address,
  receiver: Address,
  owner: Address,
  assets: BigInt,
  shares: BigInt
): Withdraw {
  let withdrawEvent = changetype<Withdraw>(newMockEvent())

  withdrawEvent.parameters = new Array()

  withdrawEvent.parameters.push(
    new ethereum.EventParam("sender", ethereum.Value.fromAddress(sender))
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam("receiver", ethereum.Value.fromAddress(receiver))
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam("assets", ethereum.Value.fromUnsignedBigInt(assets))
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam("shares", ethereum.Value.fromUnsignedBigInt(shares))
  )

  return withdrawEvent
}
