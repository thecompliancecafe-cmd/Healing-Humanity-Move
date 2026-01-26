module healing_humanity::hypercerts {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Hypercert has key {
        id: UID,
        campaign_id: u64,
        owner: address,
    }

    public entry fun mint(ctx: &mut TxContext, campaign_id: u64): Hypercert {
        Hypercert {
            id: object::new(ctx),
            campaign_id,
            owner: tx_context::sender(ctx),
        }
    }
}
