module healing_humanity::campaign_registry {

    use sui::table::{Self, Table};
    use sui::clock::Clock;
    use sui::tx_context::{Self, TxContext};
    use sui::object;
    use sui::transfer;
    use std::vector;
    use std::option;

    use healing_humanity::protocol_fees;
    use healing_humanity::circuit_breaker;
    use healing_humanity::protocol_governance;
    use healing_humanity::events;

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_INVALID_INPUT: u64 = 0;
    const E_NOT_OWNER: u64 = 1;
    const E_INVALID_STATE: u64 = 2;
    const E_ALREADY_REGISTERED: u64 = 3;
    const E_INVALID_TIER: u64 = 4;
    const E_PROTOCOL_PAUSED: u64 = 5;
    const E_NOT_AUTHORIZED: u64 = 6;
    const E_ESCROW_ALREADY_SET: u64 = 7;
    const E_ESCROW_MISMATCH: u64 = 8;

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
    /// Campaign object
    /// -----------------------------
    public struct Campaign has key {
        id: object::UID,
        name: vector<u8>,
        target: u64,
        raised: u64,
        owner: address,
        status: CampaignStatus,
        tier: u8,
        escrow_id: option::Option<object::ID>,

        /// Hypercert flags (kept)
        hypercert_eligible: bool,
        completed_at: u64
    }

    /// -----------------------------
    /// Registry
    /// -----------------------------
    public struct CampaignRegistry has key {
        id: object::UID,
        campaigns: Table<object::ID, address>,
    }

    /// -----------------------------
    /// Helpers
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

    fun assert_valid_transition(old: CampaignStatus, new: CampaignStatus) {
        if (
            (old == CampaignStatus::CREATED && new == CampaignStatus::ACTIVE) ||
            (old == CampaignStatus::ACTIVE && new == CampaignStatus::PAUSED) ||
            (old == CampaignStatus::PAUSED && new == CampaignStatus::ACTIVE) ||
            (old == CampaignStatus::ACTIVE && new == CampaignStatus::COMPLETED) ||
            (new == CampaignStatus::REVOKED)
        ) {
            return;
        };
        abort E_INVALID_STATE;
    }

    /// -----------------------------
    /// Create registry
    /// -----------------------------
    public fun create_registry(ctx: &mut TxContext) {
        let registry = CampaignRegistry {
            id: object::new(ctx),
            campaigns: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    /// -----------------------------
    /// Create campaign
    /// -----------------------------
    public fun create_campaign(
        cfg: &protocol_governance::ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        registry: &mut CampaignRegistry,
        name: vector<u8>,
        target: u64,
        tier: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);
        assert!(!circuit_breaker::campaigns_paused(cb), E_PROTOCOL_PAUSED);

        assert!(target > 0, E_INVALID_INPUT);
        assert!(!vector::is_empty(&name), E_INVALID_INPUT);

        assert!(
            tier == protocol_fees::tier_ngo() ||
            tier == protocol_fees::tier_csr(),
            E_INVALID_TIER
        );

        let campaign = Campaign {
            id: object::new(ctx),
            name,
            target,
            raised: 0,
            owner: tx_context::sender(ctx),
            status: CampaignStatus::ACTIVE,
            tier,
            escrow_id: option::none(),

            hypercert_eligible: false,
            completed_at: 0
        };

        let campaign_id = object::id(&campaign);

        assert!(
            !table::contains(&registry.campaigns, campaign_id),
            E_ALREADY_REGISTERED
        );

        table::add(&mut registry.campaigns, campaign_id, campaign.owner);

        events::emit_campaign_created(
            campaign_id,
            campaign.owner,
            campaign.name,
            target,
            clock
        );

        transfer::share_object(campaign);
    }

    /// -----------------------------
    /// ESCROW LINK
    /// -----------------------------
    public fun link_escrow_internal(
        campaign: &mut Campaign,
        escrow_id: object::ID,
        clock: &Clock
    ) {
        assert!(option::is_none(&campaign.escrow_id), E_ESCROW_ALREADY_SET);

        campaign.escrow_id = option::some(escrow_id);

        events::emit_campaign_escrow_linked(
            object::id(campaign),
            escrow_id,
            clock
        );
    }

    public fun add_funds_internal(
        campaign: &mut Campaign,
        escrow_id: object::ID,
        amount: u64,
        clock: &Clock
    ) {
        assert!(campaign.status == CampaignStatus::ACTIVE, E_INVALID_STATE);

        let stored = &campaign.escrow_id;
        assert!(option::is_some(stored), E_INVALID_STATE);

        let stored_id = *option::borrow(stored);
        assert!(stored_id == escrow_id, E_ESCROW_MISMATCH);

        campaign.raised = campaign.raised + amount;

        events::emit_campaign_funded(
            object::id(campaign),
            escrow_id,
            amount,
            campaign.raised,
            clock
        );
    }

    /// -----------------------------
    /// COMPLETION (FIXED)
    /// -----------------------------
    public fun mark_completed_internal(
        campaign: &mut Campaign,
        escrow_id: object::ID,
        clock: &Clock
    ) {
        let stored = &campaign.escrow_id;
        assert!(option::is_some(stored), E_INVALID_STATE);

        let stored_id = *option::borrow(stored);
        assert!(stored_id == escrow_id, E_ESCROW_MISMATCH);

        assert_valid_transition(campaign.status, CampaignStatus::COMPLETED);

        let old = campaign.status;
        campaign.status = CampaignStatus::COMPLETED;

        /// keep hypercert readiness logic
        campaign.hypercert_eligible = true;
        campaign.completed_at = sui::clock::timestamp_ms(clock);

        events::emit_campaign_status_changed(
            object::id(campaign),
            status_to_u8(old),
            status_to_u8(campaign.status),
            @0x0,
            b"completed",
            clock
        );

        // ❌ REMOVED ONLY THIS:
        // events::emit_campaign_completed_for_hypercert(...)
    }

    /// -----------------------------
    /// Owner controls
    /// -----------------------------
    public fun pause_campaign(
        cfg: &protocol_governance::ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        campaign: &mut Campaign,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);
        assert!(!circuit_breaker::campaigns_paused(cb), E_PROTOCOL_PAUSED);

        assert!(campaign.owner == tx_context::sender(ctx), E_NOT_OWNER);
        assert_valid_transition(campaign.status, CampaignStatus::PAUSED);

        let old = campaign.status;
        campaign.status = CampaignStatus::PAUSED;

        events::emit_campaign_status_changed(
            object::id(campaign),
            status_to_u8(old),
            status_to_u8(campaign.status),
            tx_context::sender(ctx),
            b"paused",
            clock
        );
    }

    public fun resume_campaign(
        cfg: &protocol_governance::ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        campaign: &mut Campaign,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);
        assert!(!circuit_breaker::campaigns_paused(cb), E_PROTOCOL_PAUSED);

        assert!(campaign.owner == tx_context::sender(ctx), E_NOT_OWNER);
        assert_valid_transition(campaign.status, CampaignStatus::ACTIVE);

        let old = campaign.status;
        campaign.status = CampaignStatus::ACTIVE;

        events::emit_campaign_status_changed(
            object::id(campaign),
            status_to_u8(old),
            status_to_u8(campaign.status),
            tx_context::sender(ctx),
            b"resumed",
            clock
        );
    }

    /// -----------------------------
    /// Admin control
    /// -----------------------------
    public fun revoke_campaign(
        cfg: &protocol_governance::ProtocolConfig,
        campaign: &mut Campaign,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(
            protocol_governance::is_admin(cfg, tx_context::sender(ctx)),
            E_NOT_AUTHORIZED
        );

        assert!(campaign.status != CampaignStatus::REVOKED, E_INVALID_STATE);

        let old = campaign.status;
        campaign.status = CampaignStatus::REVOKED;

        events::emit_campaign_status_changed(
            object::id(campaign),
            status_to_u8(old),
            status_to_u8(campaign.status),
            tx_context::sender(ctx),
            b"revoked",
            clock
        );
    }

    /// -----------------------------
    /// Views
    /// -----------------------------
    public fun exists(registry: &CampaignRegistry, campaign_id: object::ID): bool {
        table::contains(&registry.campaigns, campaign_id)
    }

    public fun raised_of(campaign: &Campaign): u64 {
        campaign.raised
    }

    public fun is_hypercert_ready(campaign: &Campaign): bool {
        campaign.hypercert_eligible && campaign.status == CampaignStatus::COMPLETED
    }
}
