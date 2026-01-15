import {
  EmergencyWithdraw as EmergencyWithdrawEvent,
  Pull as PullEvent,
  Push as PushEvent,
  Report as ReportEvent,
  RoleAdminChanged as RoleAdminChangedEvent,
  RoleGranted as RoleGrantedEvent,
  RoleRevoked as RoleRevokedEvent,
  StrategyPaused as StrategyPausedEvent,
  StrategyUnpaused as StrategyUnpausedEvent
} from "../generated/CompoundUsdcStrategy/CompoundUsdcStrategy"
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
} from "../generated/schema"

export function handleEmergencyWithdraw(event: EmergencyWithdrawEvent): void {
  let entity = new EmergencyWithdraw(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.timestamp = event.params.timestamp
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePull(event: PullEvent): void {
  let entity = new Pull(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.assetPull = event.params.assetPull

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePush(event: PushEvent): void {
  let entity = new Push(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.assetPush = event.params.assetPush

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleReport(event: ReportEvent): void {
  let entity = new Report(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.time = event.params.time
  entity.profit = event.params.profit
  entity.loss = event.params.loss

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRoleAdminChanged(event: RoleAdminChangedEvent): void {
  let entity = new RoleAdminChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.role = event.params.role
  entity.previousAdminRole = event.params.previousAdminRole
  entity.newAdminRole = event.params.newAdminRole

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRoleGranted(event: RoleGrantedEvent): void {
  let entity = new RoleGranted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.role = event.params.role
  entity.account = event.params.account
  entity.sender = event.params.sender

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRoleRevoked(event: RoleRevokedEvent): void {
  let entity = new RoleRevoked(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.role = event.params.role
  entity.account = event.params.account
  entity.sender = event.params.sender

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStrategyPaused(event: StrategyPausedEvent): void {
  let entity = new StrategyPaused(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleStrategyUnpaused(event: StrategyUnpausedEvent): void {
  let entity = new StrategyUnpaused(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.timestamp = event.params.timestamp

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
