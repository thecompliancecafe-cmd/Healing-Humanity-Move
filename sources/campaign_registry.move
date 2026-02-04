module healing_humanity::campaign_registry {

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::transfer;
    use std::vector;

    /// -----------------------------
    /// Events
    /// -----------------------------
    public struct CampaignCreated has copy, drop {
        campaign_id: ID,
        name: vector<u8>,
        target: u64,
        owner: address,
    }

    public struct CampaignClosed has copy, drop {
        campaign_id: ID,
    }

    /// -----------------------------
    /// Campaign object (business)
    /// -----------------------------
    public struct Campaign has key {
        id: UID,
        name: vector<u8>,
        target: u64,
        raised: u64,
        owner: address,
        is_active: bool,
    }

    /// -----------------------------
    /// Registry object (index)
    /// -----------------------------
    public struct CampaignRegistry has key {
        id: UID,
        campaigns: Table<ID, bool>,
    }

    /// -----------------------------
    /// Create the global registry (once)
    /// -----------------------------
    public entry fun create_registry(ctx: &mut TxContext) {
        let registry = CampaignRegistry {
            id: object::new(ctx),
            campaigns: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    /// -----------------------------
    /// Create + register a campaign
    /// -----------------------------
    public entry fun create_campaign(
        registry: &mut CampaignRegistry,
        name: vector<u8>,
        target: u64,
        ctx: &mut TxContext
    ) {
        assert!(target > 0, 0);
        assert!(!vector::is_empty(&name), 1);

        let campaign = Campaign {
            id: object::new(ctx),
            name,
            target,
            raised: 0,
            owner: tx_context::sender(ctx),
            is_active: true,
        };

        let campaign_id = object::id(&campaign);

        // Prevent duplicate registration
        assert!(
            !table::contains(&registry.campaigns, campaign_id),
            2
        );

        table::add(&mut registry.campaigns, campaign_id, true);

        // Emit event
        sui::event::emit(CampaignCreated {
            campaign_id,
            name: campaign.name,
            target,
            owner: campaign.owner,
        });

        transfer::share_object(campaign);
    }

    /// -----------------------------
    /// Close a campaign (owner only)
    /// -----------------------------
    public entry fun close_campaign(
        campaign: &mut Campaign,
        ctx: &TxContext
    ) {
        assert!(campaign.is_active, 3);
        assert!(campaign.owner == tx_context::sender(ctx), 4);

        campaign.is_active = false;

        sui::event::emit(CampaignClosed {
            campaign_id: object::id(campaign),
        });
    }

    /// -----------------------------
    /// Read-only helpers
    /// -----------------------------
    public fun is_registered(
        registry: &CampaignRegistry,
        campaign_id: ID
    ): bool {
        table::contains(&registry.campaigns, campaign_id)
    }

    public fun is_active(campaign: &Campaign): bool {
        campaign.is_active
    }
}
