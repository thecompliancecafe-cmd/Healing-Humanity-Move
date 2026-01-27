module healing_humanity::ledger {
    use sui::object::{UID, ID, object};
    use sui::tx_context::TxContext;

    struct LedgerEntry has key {
        id: UID,
        campaign_id: ID,
        donor: address,
        amount: u64,
    }

    public fun record(
        campaign_id: ID,
        donor: address,
        amount: u64,
        ctx: &mut TxContext
    ): LedgerEntry {
        LedgerEntry {
            id: object::new(ctx),
            campaign_id,
            donor,
            amount,
        }
    }
}
