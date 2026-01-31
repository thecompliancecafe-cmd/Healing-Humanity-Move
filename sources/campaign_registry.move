module healing_humanity::campaign_registry {

    public struct CampaignRegistry has key {
        id: sui::object::UID,
        campaigns: sui::table::Table<sui::object::ID, bool>,
    }

    public fun create(ctx: &mut sui::tx_context::TxContext) {
        let registry = CampaignRegistry {
            id: sui::object::new(ctx),
            campaigns: sui::table::new(ctx),
        };

        sui::transfer::share_object(registry);
    }

    public fun register_campaign(
        registry: &mut CampaignRegistry,
        campaign_id: sui::object::ID
    ) {
        assert!(
            !sui::table::contains(&registry.campaigns, campaign_id),
            0
        );
        sui::table::add(&mut registry.campaigns, campaign_id, true);
    }

    public fun is_registered(
        registry: &CampaignRegistry,
        campaign_id: sui::object::ID
    ): bool {
        sui::table::contains(&registry.campaigns, campaign_id)
    }
}
