module healing_humanity::campaign_registry {

    /// -----------------------------
    /// Campaign object (business)
    /// -----------------------------
    public struct Campaign has key {
        id: UID,
        name: vector<u8>,
        target: u64,
        raised: u64,
        owner: address,
    }

    /// -----------------------------
    /// Registry object (index)
    /// -----------------------------
    public struct CampaignRegistry has key {
        id: UID,
        campaigns: Table<ID, bool>,
    }

    /// Create the global registry (once)
    public entry fun create_registry(ctx: &mut TxContext) {
        let registry = CampaignRegistry {
            id: object::new(ctx),
            campaigns: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    /// Create + register a campaign
    public entry fun create_campaign(
        registry: &mut CampaignRegistry,
        name: vector<u8>,
        target: u64,
        ctx: &mut TxContext
    ) {
        assert!(target > 0, 0);

        let campaign = Campaign {
            id: object::new(ctx),
            name,
            target,
            raised: 0,
            owner: tx_context::sender(ctx),
        };

        let campaign_id = object::id(&campaign);

        assert!(
            !table::contains(&registry.campaigns, campaign_id),
            1
        );

        table::add(&mut registry.campaigns, campaign_id, true);
        transfer::share_object(campaign);
    }

    public fun is_registered(
        registry: &CampaignRegistry,
        campaign_id: ID
    ): bool {
        table::contains(&registry.campaigns, campaign_id)
    }
}
