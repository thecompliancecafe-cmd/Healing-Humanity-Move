module healing_humanity::campaign_registry {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;
    use std::string;

    struct Campaign has key {
        id: UID,
        name: string::String,
        target_goal: u64,
    }

    public fun create(
        name: string::String,
        target_goal: u64,
        ctx: &mut TxContext
    ): Campaign {
        Campaign {
            id: object::new(ctx),
            name,
            target_goal,
        }
    }
}
