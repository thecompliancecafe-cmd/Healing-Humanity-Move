module healing_humanity::ledger {

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::Clock;
    use sui::transfer;

    /// =========================
    /// STORAGE (on-chain objects)
    /// =========================

    public struct LedgerEntry has key {
        id: UID,
        campaign_id: ID,
        vault_id: ID,
        actor: address,
        amount: u64,
        kind: u8, // 0 = deposit, 1 = release
        fee: u64,
        timestamp_ms: u64,
    }

    /// =========================
    /// EVENTS
    /// =========================

    public struct DepositRecord has copy, drop {
        campaign_id: ID,
        vault_id: ID,
        amount: u64,
        timestamp_ms: u64,
    }

    public struct ReleaseRecord has copy, drop {
        campaign_id: ID,
        vault_id: ID,
        amount: u64,
        fee: u64,
        timestamp_ms: u64,
    }

    /// =========================
    /// INTERNAL
    /// =========================

    fun now(clock: &Clock): u64 {
        clock.timestamp_ms()
    }

    /// =========================
    /// CORE FUNCTIONS
    /// =========================

    /// 🔹 Generic record (kept)
    public fun record(
        campaign_id: ID,
        donor: address,
        amount: u64,
        ctx: &mut TxContext
    ): LedgerEntry {
        LedgerEntry {
            id: object::new(ctx),
            campaign_id,
            vault_id: campaign_id,
            actor: donor,
            amount,
            kind: 0,
            fee: 0,
            timestamp_ms: 0,
        }
    }

    /// 🔹 Deposit (STORE + EVENT)
    public fun record_deposit(
        campaign_id: ID,
        vault_id: ID,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let entry = LedgerEntry {
            id: object::new(ctx),
            campaign_id,
            vault_id,
            actor: tx_context::sender(ctx),
            amount,
            kind: 0,
            fee: 0,
            timestamp_ms: now(clock),
        };

        transfer::share_object(entry);

        event::emit(DepositRecord {
            campaign_id,
            vault_id,
            amount,
            timestamp_ms: now(clock),
        });
    }

    /// 🔹 Release (STORE + EVENT)
    public fun record_release(
        campaign_id: ID,
        vault_id: ID,
        amount: u64,
        fee: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let entry = LedgerEntry {
            id: object::new(ctx),
            campaign_id,
            vault_id,
            actor: tx_context::sender(ctx),
            amount,
            kind: 1,
            fee,
            timestamp_ms: now(clock),
        };

        transfer::share_object(entry);

        event::emit(ReleaseRecord {
            campaign_id,
            vault_id,
            amount,
            fee,
            timestamp_ms: now(clock),
        });
    }
}
