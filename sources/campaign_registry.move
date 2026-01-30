module healing_humanity::campaign_registry {

    use sui::table::Table;
    use sui::tx_context::TxContext;

    /// Registry of campaigns
    public struct CampaignRegistry has key {
        id: UID,
        campaigns: Table<ID, address>, // campaign_id -> owner
    }

    /// Capability to manage registry
    public struct CampaignAdminCap has key {
        id: UID,
    }

    /// Create registry and admin capability
    public fun create(ctx: &mut TxContext): CampaignAdminCap {
        let registry = CampaignRegistry {
            id: sui::object::new(ctx),
            campaigns: sui::table::new(ctx),
        };

        let cap = CampaignAdminCap {
            id: sui::object::new(ctx),
        };

        // Share registry (ownership moves here)
        sui::transfer::share_object(registry);

        // Only return the cap
        cap
    }

    /// Register a new campaign
    public fun register_campaign(
        _cap: &CampaignAdminCap,
        registry: &mut CampaignRegistry,
        campaign_id: ID,
        owner: address
    ) {
        assert!(
            !sui::table::contains(&registry.campaigns, campaign_id),
            0
        );

        sui::table::add(&mut registry.campaigns, campaign_id, owner);
    }

    /// Get campaign owner
    public fun owner_of(
        registry: &CampaignRegistry,
        campaign_id: ID
    ): address {
        *sui::table::borrow(&registry.campaigns, campaign_id)
    }

    /// Check if campaign exists
    public fun exists(
        registry: &CampaignRegistry,
        campaign_id: ID
    ): bool {
        sui::table::contains(&registry.campaigns, campaign_id)
    }
}
