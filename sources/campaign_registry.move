module healing_humanity::campaign_registry {

    use sui::table;
    use sui::table::Table;

    /// Registry of campaigns
    public struct CampaignRegistry has key {
        id: sui::object::UID,
        campaigns: Table<sui::object::ID, address>, // campaign_id -> owner
    }

    /// Capability to manage registry
    public struct CampaignAdminCap has key {
        id: sui::object::UID,
    }

    /// Create registry
    public fun create(
        ctx: &mut sui::tx_context::TxContext
    ): CampaignRegistry {
        let registry = CampaignRegistry {
            id: sui::object::new(ctx),
            campaigns: table::new(ctx),
        };

        sui::transfer::share_object(registry);
        registry
    }

    /// Register a new campaign
    public fun register_campaign(
        _cap: &CampaignAdminCap,
        registry: &mut CampaignRegistry,
        campaign_id: sui::object::ID,
        owner: address
    ) {
        assert!(
            !table::contains(&registry.campaigns, campaign_id),
            0
        );

        table::add(&mut registry.campaigns, campaign_id, owner);
    }

    /// Get campaign owner
    public fun owner_of(
        registry: &CampaignRegistry,
        campaign_id: sui::object::ID
    ): address {
        *table::borrow(&registry.campaigns, campaign_id)
    }

    /// Check if campaign exists
    public fun exists(
        registry: &CampaignRegistry,
        campaign_id: sui::object::ID
    ): bool {
        table::contains(&registry.campaigns, campaign_id)
    }
}
