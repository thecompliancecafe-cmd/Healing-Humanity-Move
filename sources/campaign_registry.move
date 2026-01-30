module healing_humanity::campaign_registry {

    use sui::object::{UID, ID};
    use sui::table;
    use sui::table::Table;
    use sui::transfer;

    /// Registry of campaigns
    public struct CampaignRegistry has key {
        id: UID,
        campaigns: Table<ID, address>, // campaign_id -> owner
    }

    /// Capability to manage registry
    public struct CampaignAdminCap has key {
        id: UID,
    }

    /// Create registry
    public fun create(
        ctx: &mut sui::tx_context::TxContext
    ): CampaignRegistry {
        let registry = CampaignRegistry {
            id: sui::object::new(ctx),
            campaigns: table::new(ctx),
        };

        transfer::share_object(registry);
        registry
    }

    /// Register a new campaign
    public fun register_campaign(
        _cap: &CampaignAdminCap,
        registry: &mut CampaignRegistry,
        campaign_id: ID,
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
        campaign_id: ID
    ): address {
        *table::borrow(&registry.campaigns, campaign_id)
    }

    /// Check if campaign exists
    public fun exists(
        registry: &CampaignRegistry,
        campaign_id: ID
    ): bool {
        table::contains(&registry.campaigns, campaign_id)
    }
}
