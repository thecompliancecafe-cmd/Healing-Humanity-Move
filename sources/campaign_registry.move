module healing_humanity::campaign_registry {

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::transfer;
    use std::vector;

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_INVALID_INPUT: u64 = 0;
    const E_NOT_OWNER: u64 = 1;
    const E_INVALID_STATE: u64 = 2;
    const E_ALREADY_REGISTERED: u64 = 3;

    /// -----------------------------
    /// Campaign lifecycle
    /// -----------------------------
    public enum CampaignStatus has copy, drop, store {
        CREATED,
        ACTIVE,
        PAUSED,
        REVOKED,
        COMPLETED,
    }

    /// -----------------------------
    /// Events
    /// -----------------------------
    public struct CampaignCreated has copy, drop {
        campaign_id: ID,
        owner: address,
        target: u64,
    }

    public struct CampaignStatusChanged has copy, drop {
        campaign_id: ID,
        old_status: u8,
        new_status: u8,
    }

    /// -----------------------------
    /// Campaign object
    /// -----------------------------
    public struct Campaign has key {
        id: UID,
        name: vector<u8>,
        target: u64,
        owner: address,
        status: CampaignStatus,
    }

    /// -----------------------------
    /// Registry object (existence only)
    /// -----------------------------
    public struct CampaignRegistry has key {
        id: UID,
        campaigns: Table<ID, bool>,
    }

    /// -----------------------------
    /// Internal helpers
    /// -----------------------------
    fun status_to_u8(status: CampaignStatus): u8 {
        match (status) {
            CampaignStatus::CREATED => 0,
            CampaignStatus::ACTIVE => 1,
            CampaignStatus::PAUSED => 2,
            CampaignStatus::REVOKED => 3,
            CampaignStatus::COMPLETED => 4,
        }
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
        assert!(target > 0, E_INVALID_INPUT);
        assert!(!vector::is_empty(&name), E_INVALID_INPUT);

        let campaign = Campaign {
            id: object::new(ctx),
            name,
            target,
            owner: tx_context::sender(ctx),
            status: CampaignStatus::ACTIVE,
        };

        let campaign_id = object::id(&campaign);

        assert!(
            !table::contains(&registry.campaigns, campaign_id),
            E_ALREADY_REGISTERED
        );

        table::add(&mut registry.campaigns, campaign_id, true);

        sui::event::emit(CampaignCreated {
            campaign_id,
            owner: campaign.owner,
            target,
        });

        transfer::share_object(campaign);
    }

    /// -----------------------------
    /// Owner controls
    /// -----------------------------
    public entry fun pause_campaign(
        campaign: &mut Campaign,
        ctx: &TxContext
    ) {
        assert!(campaign.owner == tx_context::sender(ctx), E_NOT_OWNER);
        assert!(campaign.status == CampaignStatus::ACTIVE, E_INVALID_STATE);

        let old = campaign.status;
        campaign.status = CampaignStatus::PAUSED;

        sui::event::emit(CampaignStatusChanged {
            campaign_id: object::id(campaign),
            old_status: status_to_u8(old),
            new_status: status_to_u8(campaign.status),
        });
    }

    public entry fun resume_campaign(
        campaign: &mut Campaign,
        ctx: &TxContext
    ) {
        assert!(campaign.owner == tx_context::sender(ctx), E_NOT_OWNER);
        assert!(campaign.status == CampaignStatus::PAUSED, E_INVALID_STATE);

        let old = campaign.status;
        campaign.status = CampaignStatus::ACTIVE;

        sui::event::emit(CampaignStatusChanged {
            campaign_id: object::id(campaign),
            old_status: status_to_u8(old),
            new_status: status_to_u8(campaign.status),
        });
    }

    /// -----------------------------
    /// Admin / compliance controls
    /// -----------------------------
    public entry fun revoke_campaign(
        campaign: &mut Campaign
    ) {
        assert!(campaign.status != CampaignStatus::REVOKED, E_INVALID_STATE);

        let old = campaign.status;
        campaign.status = CampaignStatus::REVOKED;

        sui::event::emit(CampaignStatusChanged {
            campaign_id: object::id(campaign),
            old_status: status_to_u8(old),
            new_status: status_to_u8(campaign.status),
        });
    }

    /// -----------------------------
    /// Read-only helpers (ESCROW USES THESE)
    /// -----------------------------
    public fun exists(
        registry: &CampaignRegistry,
        campaign_id: ID
    ): bool {
        table::contains(&registry.campaigns, campaign_id)
    }

    public fun is_active(campaign: &Campaign): bool {
        campaign.status == CampaignStatus::ACTIVE
    }

    public fun owner_of(campaign: &Campaign): address {
        campaign.owner
    }
}
