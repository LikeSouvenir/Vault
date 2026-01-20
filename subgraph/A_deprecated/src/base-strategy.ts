import {
    BaseStrategy,
    EmergencyWithdraw as EmergencyWithdrawEvent,
    Pull as PullEvent,
    Push as PushEvent,
    Report as ReportEvent,
    RoleAdminChanged as RoleAdminChangedEvent,
    RoleGranted as RoleGrantedEvent,
    RoleRevoked as RoleRevokedEvent,
    StrategyPaused as StrategyPausedEvent,
    StrategyUnpaused as StrategyUnpausedEvent
} from "../generated/templates/BaseStrategy/BaseStrategy"
import {
    StrategyEmergencyWithdraw,
    StrategyPull,
    StrategyPush,
    StrategyReport,
    StrategyRoleAdminChanged,
    StrategyRoleGranted,
    StrategyRoleRevoked,
    StrategyPaused,
    StrategyUnpaused,
    StrategyMetaInfo
} from "../generated/schema"
import {Address, Bytes} from "@graphprotocol/graph-ts";

export function handleStrategyEmergencyWithdraw(event: EmergencyWithdrawEvent): void {
    let entity = new StrategyEmergencyWithdraw(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.address
    entity.timestamp = event.params.timestamp
    entity.amount = event.params.amount

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    updateStrategyPauseMetaInfo(event.address, true)

    entity.save()
}

export function handleStrategyPull(event: PullEvent): void {
    let entity = new StrategyPull(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.address
    entity.assetPull = event.params.assetPull

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    callAndUpdateStrategyTotalAssets(event.address)

    entity.save()
}

export function handleStrategyPush(event: PushEvent): void {
    let entity = new StrategyPush(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.address
    entity.assetPush = event.params.assetPush

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    callAndUpdateStrategyTotalAssets(event.address)

    entity.save()
}

export function handleStrategyReport(event: ReportEvent): void {
    let entity = new StrategyReport(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.address
    entity.time = event.params.time
    entity.profit = event.params.profit
    entity.loss = event.params.loss

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    callAndUpdateStrategyTotalAssets(event.address)

    entity.save()
}

export function handleStrategyRoleAdminChanged(event: RoleAdminChangedEvent): void {
    let entity = new StrategyRoleAdminChanged(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.address
    entity.role = event.params.role
    entity.previousAdminRole = event.params.previousAdminRole
    entity.newAdminRole = event.params.newAdminRole

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleStrategyRoleGranted(event: RoleGrantedEvent): void {
    let entity = new StrategyRoleGranted(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.address
    entity.role = event.params.role
    entity.account = event.params.account
    entity.sender = event.params.sender

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleStrategyRoleRevoked(event: RoleRevokedEvent): void {
    let entity = new StrategyRoleRevoked(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.address
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
    entity.strategy = event.address
    entity.timestamp = event.params.timestamp

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    updateStrategyPauseMetaInfo(event.address, true)

    entity.save()
}

export function handleStrategyUnpaused(event: StrategyUnpausedEvent): void {
    let entity = new StrategyUnpaused(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.address
    entity.timestamp = event.params.timestamp

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    updateStrategyPauseMetaInfo(event.address, false)

    entity.save()
}

function updateStrategyPauseMetaInfo(strategy: Bytes, isPaused: boolean): void {
    let metaInfo = StrategyMetaInfo.load(strategy)
    if (metaInfo) {
        metaInfo.isPaused = isPaused;
    }
}

function callAndUpdateStrategyTotalAssets(strategy: Bytes): void {
    let metaInfo = StrategyMetaInfo.load(strategy)
    if (metaInfo) {
        let strategyContract = BaseStrategy.bind(Address.fromBytes(strategy))
        let totalAssetsMetaInfo = strategyContract.try_lastTotalAssets();
        if (!totalAssetsMetaInfo.reverted) {
            metaInfo.totalAssets = totalAssetsMetaInfo.value;
            metaInfo.save()
        }
    }
}
