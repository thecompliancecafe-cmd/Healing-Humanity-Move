module healing_humanity::ledger {

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
            id: sui::object::new(ctx),
            campaign_id,
            donor,
            amount,
        }
    }
}
