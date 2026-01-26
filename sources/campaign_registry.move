module healing_humanity::campaign_registry {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Campaign has store {
        creator: address,
        goal: u64,
        raised: u64,
    }

    struct CampaignRegistry has key {
        id: UID,
        campaigns: vector<Campaign>,
    }

    public entry fun init(ctx: &mut TxContext): CampaignRegistry {
        CampaignRegistry {
            id: object::new(ctx),
            campaigns: vector::empty(),
        }
    }
}
