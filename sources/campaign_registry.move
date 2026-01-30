module healing_humanity::campaign_registry {
    use sui::object::{self, UID};
    use sui::tx_context::TxContext;
    use std::string;

    /// Campaign registry object
    public struct Campaign has key {
        id: UID,
        name: string::String,
        target_goal: u64,
    }

    /// Create a new campaign
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
