module healing_humanity::campaign_registry {

    /// Campaign object
    public struct Campaign has key {
        id: sui::object::UID,
        owner: address,
        metadata: vector<u8>,
    }

    /// Create a new campaign
    public fun create(
        owner: address,
        metadata: vector<u8>,
        ctx: &mut sui::tx_context::TxContext
    ): Campaign {
        Campaign {
            id: sui::object::new(ctx),
            owner,
            metadata,
        }
    }
}
