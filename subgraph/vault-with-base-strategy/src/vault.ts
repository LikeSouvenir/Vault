import {
    Approval as ApprovalEvent,
    Deposit as DepositEvent,
    Reported as ReportedEvent,
    RoleAdminChanged as RoleAdminChangedEvent,
    RoleGranted as RoleGrantedEvent,
    RoleRevoked as RoleRevokedEvent,
    StrategyAdded as StrategyAddedEvent,
    StrategyMigrated as StrategyMigratedEvent,
    StrategyRemoved as StrategyRemovedEvent,
    Transfer as TransferEvent,
    UpdateManagementFee as UpdateManagementFeeEvent,
    UpdateManagementRecipient as UpdateManagementRecipientEvent,
    UpdatePerformanceFee as UpdatePerformanceFeeEvent,
    UpdateStrategyInfo as UpdateStrategyInfoEvent,
    UpdateStrategySharePercent as UpdateStrategySharePercentEvent,
    UpdateWithdrawalQueue as UpdateWithdrawalQueueEvent,
    Withdraw as WithdrawEvent
} from "../generated/Vault/Vault"
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
    Withdraw,
    StrategyMetaInfo
} from "../generated/schema"
import {Address, BigInt, Bytes, ethereum} from "@graphprotocol/graph-ts"
import {BaseStrategy as BaseStrategyTemplate} from "../generated/templates";
import {BaseStrategy} from "../generated/templates/BaseStrategy/BaseStrategy";

export function handleApproval(event: ApprovalEvent): void {
    let entity = new Approval(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.owner = event.params.owner
    entity.spender = event.params.spender
    entity.value = event.params.value

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleDeposit(event: DepositEvent): void {
    let entity = new Deposit(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.sender = event.params.sender
    entity.owner = event.params.owner
    entity.assets = event.params.assets
    entity.shares = event.params.shares

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleReported(event: ReportedEvent): void {
    let entity = new Reported(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.profit = event.params.profit
    entity.loss = event.params.loss
    entity.managementFees = event.params.managementFees
    entity.performanceFees = event.params.performanceFees

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

export function handleStrategyAdded(event: StrategyAddedEvent): void {
    BaseStrategyTemplate.create(event.params.strategy)
    let entity = new StrategyAdded(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.params.strategy

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    createStrategyMetaInfoEntity(event, event.params.strategy)

    entity.save()
}

export function handleStrategyMigrated(event: StrategyMigratedEvent): void {
    BaseStrategyTemplate.create(event.params.newVersion)
    let entity = new StrategyMigrated(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.oldVersion = event.params.oldVersion
    entity.newVersion = event.params.newVersion

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    removeStrategyMetaInfoEntity(event, event.params.oldVersion)
    createStrategyMetaInfoEntity(event, event.params.newVersion)

    entity.save()
}


export function handleStrategyRemoved(event: StrategyRemovedEvent): void {
    let entity = new StrategyRemoved(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.params.strategy
    entity.totalAssets = event.params.totalAssets

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    removeStrategyMetaInfoEntity(event, event.params.strategy)

    entity.save()
}

function createStrategyMetaInfoEntity(event: ethereum.Event, strategyAddress: Bytes): void {
    let newMetaInfo = StrategyMetaInfo.load(strategyAddress)
    if (!newMetaInfo) newMetaInfo = new StrategyMetaInfo(strategyAddress)
    newMetaInfo.vault = event.address
    newMetaInfo.addedAt = event.block.timestamp
    newMetaInfo.isPaused = false
    newMetaInfo.totalAssets = BigInt.zero()

    let strategyContract = BaseStrategy.bind(Address.fromBytes(strategyAddress))

    let name = strategyContract.try_name()
    if (!name.reverted) newMetaInfo.name = name.value

    newMetaInfo.save()
}

function removeStrategyMetaInfoEntity(event: ethereum.Event, strategyAddress: Bytes): void {
    let oldMetaInfo = StrategyMetaInfo.load(strategyAddress)
    if (oldMetaInfo) {
        oldMetaInfo.removedAt = event.block.timestamp
        oldMetaInfo.isPaused = true
        oldMetaInfo.sharePercent = BigInt.zero();
        oldMetaInfo.totalAssets = BigInt.zero();

        oldMetaInfo.save()
    }
}

export function handleTransfer(event: TransferEvent): void {
    let entity = new Transfer(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.from = event.params.from
    entity.to = event.params.to
    entity.value = event.params.value

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleUpdateManagementFee(
    event: UpdateManagementFeeEvent
): void {
    let entity = new UpdateManagementFee(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.fee = event.params.fee

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleUpdateManagementRecipient(
    event: UpdateManagementRecipientEvent
): void {
    let entity = new UpdateManagementRecipient(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.recipient = event.params.recipient

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleUpdatePerformanceFee(
    event: UpdatePerformanceFeeEvent
): void {
    let entity = new UpdatePerformanceFee(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.params.strategy
    entity.newFee = event.params.newFee

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleUpdateStrategyInfo(event: UpdateStrategyInfoEvent): void {
    let entity = new UpdateStrategyInfo(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.params.strategy
    entity.newBalance = event.params.newBalance

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleUpdateStrategySharePercent(
    event: UpdateStrategySharePercentEvent
): void {
    let entity = new UpdateStrategySharePercent(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.strategy = event.params.strategy
    entity.newPercent = event.params.newPercent

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    let metaInfo = StrategyMetaInfo.load(event.params.strategy)
    if (!metaInfo) metaInfo = new StrategyMetaInfo(event.params.strategy)
    metaInfo.sharePercent = event.params.newPercent;

    entity.save()
    metaInfo.save()
}

export function handleUpdateWithdrawalQueue(
    event: UpdateWithdrawalQueueEvent
): void {
    let entity = new UpdateWithdrawalQueue(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.queue = changetype<Bytes[]>(event.params.queue)

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}

export function handleWithdraw(event: WithdrawEvent): void {
    let entity = new Withdraw(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )
    entity.sender = event.params.sender
    entity.receiver = event.params.receiver
    entity.owner = event.params.owner
    entity.assets = event.params.assets
    entity.shares = event.params.shares

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}