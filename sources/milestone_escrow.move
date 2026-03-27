module healing_humanity::milestone_escrow {

    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::tx_context;
    use sui::object;
    use sui::transfer;
    use sui::table::{Self, Table};

    use healing_humanity::protocol_fees;
    use healing_humanity::treasury;
    use healing_humanity::treasury::Treasury;
    use healing_humanity::circuit_breaker;
    use healing_humanity::protocol_governance;
    use healing_humanity::protocol_governance::ProtocolConfig;
    use healing_humanity::identity;

    use healing_humanity::ai_oracle;
    use healing_humanity::ai_oracle::OracleRegistry;
    use healing_humanity::ai_attestation::{Self, Attestation};

    use healing_humanity::reputation::{Self, XPRegistry};

    /// ------------------------
    /// Errors
    /// ------------------------
    const E_CAMPAIGN_MISMATCH: u64 = 0;
    const E_MILESTONE_INVALID: u64 = 1;
    const E_MILESTONE_ALREADY_RELEASED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_ESCROW_CLOSED: u64 = 4;
    const E_ESCROW_PAUSED: u64 = 5;
    const E_IDENTITY_INACTIVE: u64 = 6;

    const E_NOT_ENOUGH_APPROVALS: u64 = 7;
    const E_ALREADY_APPROVED: u64 = 8;
    const E_NOT_ORACLE: u64 = 9;

    const E_ALREADY_USED: u64 = 10;
    const E_INVALID_ATTESTATION: u64 = 11;

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

        approvals: Table<u64, vector<object::ID>>,
        quorum_threshold: u64,
        used_attestations: Table<object::ID, bool>,
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
    /// Create
    /// ------------------------
    public fun create(
        cfg: &ProtocolConfig,
        campaign_id: object::ID,
        campaign_owner_identity: &identity::Identity,
        tier: u8,
        initial_coin: Coin<sui::sui::SUI>,
        milestone_amounts: vector<u64>,
        quorum_threshold: u64,
        ctx: &mut tx_context::TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);

        assert!(identity::is_active(campaign_owner_identity), E_IDENTITY_INACTIVE);

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
            campaign_id,
            campaign_owner_identity: object::id(campaign_owner_identity),
            tier,
            balance,
            milestones,
            closed: false,

            approvals: table::new(ctx),
            quorum_threshold,
            used_attestations: table::new(ctx),
        };

        let cap = EscrowCap {
            id: object::new(ctx),
            campaign_id,
            owner_identity: object::id(campaign_owner_identity),
        };

        transfer::share_object(vault);
        transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// ------------------------
    /// Submit approval (FIXED)
    /// ------------------------
    public fun submit_approval(
        registry: &OracleRegistry,
        xp_registry: &mut XPRegistry,
        vault: &mut Vault,
        attestation: &Attestation,
        oracle_identity: &identity::Identity
    ) {
        let att_id = object::id(attestation);

        assert!(
            !table::contains(&vault.used_attestations, att_id),
            E_ALREADY_USED
        );

        let milestone_id = ai_attestation::milestone_of(attestation);
        let oracle_id = ai_attestation::oracle_identity_of(attestation);

        assert!(
            ai_attestation::campaign_of(attestation) == vault.campaign_id,
            E_INVALID_ATTESTATION
        );

        let len = vector::length(&vault.milestones);
        assert!(milestone_id < len, E_INVALID_ATTESTATION);

        assert!(
            ai_oracle::is_oracle_id(registry, oracle_id),
            E_NOT_ORACLE
        );

        assert!(
            object::id(oracle_identity) == oracle_id,
            E_NOT_ORACLE
        );

        if (!table::contains(&vault.approvals, milestone_id)) {
            table::add(&mut vault.approvals, milestone_id, vector::empty<object::ID>());
        };

        let approvals_vec =
            table::borrow_mut(&mut vault.approvals, milestone_id);

        let mut i = 0;
        let len2 = vector::length(approvals_vec);

        while (i < len2) {
            assert!(
                *vector::borrow(approvals_vec, i) != oracle_id,
                E_ALREADY_APPROVED
            );
            i = i + 1;
        };

        vector::push_back(approvals_vec, oracle_id);

        table::add(&mut vault.used_attestations, att_id, true);

        reputation::add_xp(xp_registry, oracle_identity, 10);
    }

    /// ------------------------
    /// Slash oracle (XP penalty)
    /// ------------------------
    public fun slash_oracle(
        xp_registry: &mut XPRegistry,
        oracle_identity: &identity::Identity,
        amount: u64
    ) {
        reputation::slash_xp(xp_registry, oracle_identity, amount);
    }

    /// ------------------------
    /// Deposit
    /// ------------------------
    public fun deposit(
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        vault: &mut Vault,
        coin: Coin<sui::sui::SUI>
    ) {
        protocol_governance::assert_protocol_active(cfg);

        assert!(!circuit_breaker::escrow_paused(cb), E_ESCROW_PAUSED);
        assert!(!vault.closed, E_ESCROW_CLOSED);

        balance::join(&mut vault.balance, coin::into_balance(coin));
    }

    /// ------------------------
    /// Release milestone
    /// ------------------------
    public fun release_milestone(
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        fee_config: &protocol_fees::ProtocolFeeConfig,
        cap: &EscrowCap,
        vault: &mut Vault,
        milestone_id: u64,
        recipient_identity: &identity::Identity,
        treasury: &mut Treasury,
        ctx: &mut tx_context::TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);

        assert!(!circuit_breaker::escrow_paused(cb), E_ESCROW_PAUSED);
        assert!(!vault.closed, E_ESCROW_CLOSED);

        assert!(cap.campaign_id == vault.campaign_id, E_CAMPAIGN_MISMATCH);

        assert!(identity::is_active(recipient_identity), E_IDENTITY_INACTIVE);

        let len = vector::length(&vault.milestones);
        assert!(milestone_id < len, E_MILESTONE_INVALID);

        let approvals = table::borrow(&vault.approvals, milestone_id);

        assert!(
            vector::length(approvals) >= vault.quorum_threshold,
            E_NOT_ENOUGH_APPROVALS
        );

        let milestone =
            vector::borrow_mut(&mut vault.milestones, milestone_id);

        assert!(!milestone.released, E_MILESTONE_ALREADY_RELEASED);

        let amount = milestone.amount;

        assert!(
            balance::value(&vault.balance) >= amount,
            E_INSUFFICIENT_BALANCE
        );

        let fee = protocol_fees::compute_fee(fee_config, amount, vault.tier);

        let mut milestone_balance =
            balance::split(&mut vault.balance, amount);

        let fee_balance =
            balance::split(&mut milestone_balance, fee);

        milestone.released = true;

        let fee_coin = coin::from_balance(fee_balance, ctx);

        treasury::deposit(cfg, treasury, fee_coin, ctx);

        let recipient_wallet =
            identity::get_owner(recipient_identity);

        transfer::public_transfer(
            coin::from_balance(milestone_balance, ctx),
            recipient_wallet
        );
    }

    /// ------------------------
    /// Close
    /// ------------------------
    public fun close(
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        cap: &EscrowCap,
        vault: &mut Vault
    ) {
        protocol_governance::assert_protocol_active(cfg);

        assert!(!circuit_breaker::escrow_paused(cb), E_ESCROW_PAUSED);

        assert!(
            cap.campaign_id == vault.campaign_id,
            E_CAMPAIGN_MISMATCH
        );

        vault.closed = true;
    }
}
