module healing_humanity::ledger {
    use sui::object::{UID, ID};
    use sui::tx_context::TxContext;

    /// Immutable ledger entry for audit trails
    public struct LedgerEntry has key {
        id: UID,
        campaign_id: ID,
        donor: address,
        amount: u64,
    }

    /// Record a donation into the on-chain ledger
    public fun record(
        campaign_id: ID,
        donor: address,
        amount: u64,
        ctx: &mut TxContext
    ): LedgerEntry {
        LedgerEntry {
            id: UID::new(ctx),
            campaign_id,
            donor,
            amount,
        }
    }
}
