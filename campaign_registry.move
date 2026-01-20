module healing_humanity::campaign_registry {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::string::String;
    use sui::clock::Clock;
    use healing_humanity::compliance;

    struct Campaign has key, store {
        id: UID,
        name: String,
        charity_wallet: address,
        target_goal: u64,
        created_at: u64,
    }

    public fun create_campaign(
        registry: &compliance::ComplianceRegistry,
        name: String,
        charity_wallet: address,
        target_goal: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): Campaign {
        assert!(compliance::is_compliant(registry, charity_wallet), 1);

        Campaign {
            id: object::new(ctx),
            name,
            charity_wallet,
            target_goal,
            created_at: clock::now_ms(clock),
        }
    }
}
