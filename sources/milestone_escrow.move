module healing_humanity::milestone_escrow {

    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::Clock;

    use healing_humanity::protocol_fees;
    use healing_humanity::treasury;
    use healing_humanity::treasury::Treasury;
    use healing_humanity::circuit_breaker;
    use healing_humanity::protocol_governance;
    use healing_humanity::protocol_governance::ProtocolConfig;
    use healing_humanity::identity;

    use healing_humanity::ai_oracle;
    use healing_humanity::ai_oracle::OracleRegistry;

    use healing_humanity::events;
    use healing_humanity::campaign_registry;
    use healing_humanity::ledger;

    /// ------------------------
    /// Errors
    /// ------------------------
    const E_CAMPAIGN_MISMATCH: u64 = 0;
    const E_MILESTONE_ALREADY_RELEASED: u64 = 2;
    const E_ESCROW_CLOSED: u64 = 4;
    const E_ESCROW_PAUSED: u64 = 5;
    const E_IDENTITY_INACTIVE: u64 = 6;
    const E_ORACLE_NOT_APPROVED: u64 = 12;

    /// ------------------------
    /// Milestone
    /// ------------------------
    public struct Milestone has store, drop {
        id: u64,
        amount: u64,
        released: bool,
    }

    /// ------------------------
    /// Vault
    /// ------------------------
    public struct Vault has key {
        id: object::UID,
        campaign_id: object::ID,
        campaign_owner_identity: object::ID,
        tier: u8,
        balance: Balance<sui::sui::SUI>,
        milestones: vector<Milestone>,
        closed: bool,
        quorum_threshold: u64,
        round: u64,
    }

    /// ------------------------
    /// EscrowCap
    /// ------------------------
    public struct EscrowCap has key {
        id: object::UID,
        campaign_id: object::ID,
        owner_identity: object::ID,
    }

    /// ------------------------
    /// Helpers
    /// ------------------------
    fun all_released(vault: &Vault): bool {
        let mut i = 0;
        let len = vector::length(&vault.milestones);

        while (i < len) {
            if (!vector::borrow(&vault.milestones, i).released) {
                return false;
            };
            i = i + 1;
        };
        true
    }

    /// ------------------------
    /// Create
    /// ------------------------
    public fun create(
        cfg: &ProtocolConfig,
        campaign: &mut campaign_registry::Campaign,
        campaign_owner_identity: &identity::Identity,
        tier: u8,
        initial_coin: Coin<sui::sui::SUI>,
        milestone_amounts: vector<u64>,
        quorum_threshold: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);
        assert!(identity::is_active(campaign_owner_identity), E_IDENTITY_INACTIVE);

        let initial_amount = coin::value(&initial_coin);
        let balance = coin::into_balance(initial_coin);

        let mut milestones = vector::empty<Milestone>();
        let mut i = 0;
        let len = vector::length(&milestone_amounts);

        while (i < len) {
            vector::push_back(
                &mut milestones,
                Milestone {
                    id: i,
                    amount: *vector::borrow(&milestone_amounts, i),
                    released: false
                }
            );
            i = i + 1;
        };

        let vault = Vault {
            id: object::new(ctx),
            campaign_id: object::id(campaign),
            campaign_owner_identity: object::id(campaign_owner_identity),
            tier,
            balance,
            milestones,
            closed: false,
            quorum_threshold,
            round: 0
        };

        let vault_id = object::id(&vault);

        campaign_registry::link_escrow_internal(campaign, vault_id, clock);

        events::emit_escrow_created(
            vault.campaign_id,
            vault_id,
            initial_amount,
            clock
        );

        ledger::record_deposit(
            vault.campaign_id,
            vault_id,
            initial_amount,
            clock,
            ctx
        );

        let cap = EscrowCap {
            id: object::new(ctx),
            campaign_id: vault.campaign_id,
            owner_identity: object::id(campaign_owner_identity),
        };

        transfer::share_object(vault);
        transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// ------------------------
    /// Deposit
    /// ------------------------
    public fun deposit(
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        campaign: &mut campaign_registry::Campaign,
        vault: &mut Vault,
        coin: Coin<sui::sui::SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);

        assert!(!circuit_breaker::escrow_paused(cb), E_ESCROW_PAUSED);
        assert!(!vault.closed, E_ESCROW_CLOSED);

        let amount = coin::value(&coin);

        balance::join(&mut vault.balance, coin::into_balance(coin));

        campaign_registry::add_funds_internal(
            campaign,
            object::id(vault),
            amount,
            clock
        );

        events::emit_escrow_funded(
            vault.campaign_id,
            object::id(vault),
            tx_context::sender(ctx),
            amount,
            clock
        );

        ledger::record_deposit(
            vault.campaign_id,
            object::id(vault),
            amount,
            clock,
            ctx
        );
    }

    /// ------------------------
    /// Release milestone
    /// ------------------------
    public fun release_milestone(
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        fee_config: &protocol_fees::ProtocolFeeConfig,
        campaign: &mut campaign_registry::Campaign,
        cap: &EscrowCap,
        vault: &mut Vault,
        milestone_id: u64,
        recipient_identity: &identity::Identity,
        treasury: &mut Treasury,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);

        assert!(!circuit_breaker::escrow_paused(cb), E_ESCROW_PAUSED);
        assert!(!vault.closed, E_ESCROW_CLOSED);
        assert!(cap.campaign_id == vault.campaign_id, E_CAMPAIGN_MISMATCH);

        let milestone = vector::borrow_mut(&mut vault.milestones, milestone_id);
        assert!(!milestone.released, E_MILESTONE_ALREADY_RELEASED);

        let amount = milestone.amount;
        let fee = protocol_fees::compute_fee(fee_config, amount, vault.tier);

        let mut milestone_balance = balance::split(&mut vault.balance, amount);
        let fee_balance = balance::split(&mut milestone_balance, fee);

        milestone.released = true;

        treasury::deposit(
            cfg,
            treasury,
            coin::from_balance(fee_balance, ctx),
            ctx
        );

        let recipient_wallet = identity::get_owner(recipient_identity);

        transfer::public_transfer(
            coin::from_balance(milestone_balance, ctx),
            recipient_wallet
        );

        events::emit_escrow_released(
            vault.campaign_id,
            object::id(vault),
            milestone_id,
            recipient_wallet,
            amount,
            fee,
            clock
        );

        ledger::record_release(
            vault.campaign_id,
            object::id(vault),
            amount,
            fee,
            clock,
            ctx
        );

        if (all_released(vault)) {
            campaign_registry::mark_completed_internal(
                campaign,
                object::id(vault),
                clock
            );
        }
    }

    /// ------------------------
    /// Oracle-Gated Release (MAIN PATH)
    /// ------------------------
    public fun release_milestone_with_oracle(
        registry: &OracleRegistry,
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        fee_config: &protocol_fees::ProtocolFeeConfig,
        campaign: &mut campaign_registry::Campaign,
        cap: &EscrowCap,
        vault: &mut Vault,
        milestone_id: u64,
        round: u64,
        recipient_identity: &identity::Identity,
        treasury: &mut Treasury,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let approved = ai_oracle::is_round_approved(
            registry,
            vault.campaign_id,
            object::id(vault),
            milestone_id,
            round
        );

        assert!(approved, E_ORACLE_NOT_APPROVED);

        release_milestone(
            cfg,
            cb,
            fee_config,
            campaign,
            cap,
            vault,
            milestone_id,
            recipient_identity,
            treasury,
            clock,
            ctx
        );
    }

    /// ------------------------
    /// Close
    /// ------------------------
    public fun close(
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        cap: &EscrowCap,
        vault: &mut Vault,
        clock: &Clock
    ) {
        protocol_governance::assert_protocol_active(cfg);

        assert!(!circuit_breaker::escrow_paused(cb), E_ESCROW_PAUSED);
        assert!(cap.campaign_id == vault.campaign_id, E_CAMPAIGN_MISMATCH);

        vault.closed = true;

        events::emit_escrow_closed(
            vault.campaign_id,
            object::id(vault),
            clock
        );
    }
}
