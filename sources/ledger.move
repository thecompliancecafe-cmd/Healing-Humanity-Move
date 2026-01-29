module healing_humanity::ledger {
    use sui::object::UID;
    use sui::tx_context::TxContext;

    /// Immutable ledger entry for audit trails
    public struct LedgerEntry has key {
        id: UID,
        campaign_id: UID,
        donor: address,
        amount: u64,
    }

    /// Record a donation into the on-chain ledger
    public fun record(
        campaign_id: UID,
        donor: address,
        amount: u64,
        ctx: &mut TxContext
    ): LedgerEntry {
        LedgerEntry {
            id: sui::object::new(ctx),
            campaign_id,
            donor,
            amount,
        }
    }
}
