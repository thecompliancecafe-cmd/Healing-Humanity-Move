module healing_humanity::hypercerts {
    use sui::object::{UID, ID, object};
    use sui::tx_context::TxContext;
    use std::string;

    struct Hypercert has key {
        id: UID,
        donor: address,
        campaign_id: ID,
        metadata: string::String,
    }

    public fun mint(
        donor: address,
        campaign_id: ID,
        metadata: string::String,
        ctx: &mut TxContext
    ): Hypercert {
        Hypercert {
            id: object::new(ctx),
            donor,
            campaign_id,
            metadata,
        }
    }
}
