module healing_humanity::campaign_registry {

    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::table::{Self, Table};
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

    /// Create registry and admin capability
    public fun create(
        ctx: &mut TxContext
    ): (CampaignRegistry, CampaignAdminCap) {
        let registry = CampaignRegistry {
            id: object::new(ctx),
            campaigns: table::new(ctx),
        };

        let cap = CampaignAdminCap {
            id: object::new(ctx),
        };

        // Registry must be shared
        transfer::share_object(registry);

        (registry, cap)
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

    /// Check campaign owner
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
