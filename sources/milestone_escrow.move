module healing_humanity::milestone_escrow {

    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};

    use healing_humanity::protocol_fees;
    use healing_humanity::treasury;
    use healing_humanity::treasury::Treasury;
    use healing_humanity::circuit_breaker;
    use healing_humanity::protocol_governance;
    use healing_humanity::protocol_governance::ProtocolConfig;
    use healing_humanity::identity;

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

    /// ------------------------
    /// Milestone State
    /// ------------------------
    public struct Milestone has store, drop {
        id: u64,
        amount: u64,
        released: bool,
    }

    /// ------------------------
    /// Escrow Vault (SHARED)
    /// ------------------------
    public struct Vault has key {
        id: UID,
        campaign_id: ID,
        campaign_owner_identity: ID,
        tier: u8,
        balance: Balance<sui::sui::SUI>,
        milestones: vector<Milestone>,
        closed: bool,
    }

    /// ------------------------
    /// Escrow Capability (OWNED)
    /// ------------------------
    public struct EscrowCap has key {
        id: UID,
        campaign_id: ID,
        owner_identity: ID,
    }

    /// ------------------------
    /// Create escrow
    /// ------------------------
    public fun create(
        cfg: &ProtocolConfig,
        campaign_id: ID,
        campaign_owner_identity: &identity::Identity,
        tier: u8,
        initial_coin: Coin<sui::sui::SUI>,
        milestone_amounts: vector<u64>,
        ctx: &mut TxContext
    ) {

        protocol_governance::assert_protocol_active(cfg);

        // Ensure campaign identity is active
        assert!(
            identity::is_active(campaign_owner_identity),
            E_IDENTITY_INACTIVE
        );

        let balance = coin::into_balance(initial_coin);
        let mut milestones = vector::empty<Milestone>();

        let mut i = 0;
        let len = vector::length(&milestone_amounts);

        while (i < len) {

            let amt = *vector::borrow(&milestone_amounts, i);

            vector::push_back(
                &mut milestones,
                Milestone {
                    id: i,
                    amount: amt,
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
    /// Deposit funds
    /// ------------------------
    public fun deposit(
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        vault: &mut Vault,
        coin: Coin<sui::sui::SUI>
    ) {

        protocol_governance::assert_protocol_active(cfg);

        assert!(
            !circuit_breaker::escrow_paused(cb),
            E_ESCROW_PAUSED
        );

        assert!(!vault.closed, E_ESCROW_CLOSED);

        balance::join(
            &mut vault.balance,
            coin::into_balance(coin)
        );
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
        ctx: &mut TxContext
    ) {

        protocol_governance::assert_protocol_active(cfg);

        assert!(
            !circuit_breaker::escrow_paused(cb),
            E_ESCROW_PAUSED
        );

        assert!(!vault.closed, E_ESCROW_CLOSED);

        assert!(
            cap.campaign_id == vault.campaign_id,
            E_CAMPAIGN_MISMATCH
        );

        // Ensure recipient identity is active
        assert!(
            identity::is_active(recipient_identity),
            E_IDENTITY_INACTIVE
        );

        let len = vector::length(&vault.milestones);

        assert!(
            milestone_id < len,
            E_MILESTONE_INVALID
        );

        let milestone =
            vector::borrow_mut(&mut vault.milestones, milestone_id);

        assert!(
            !milestone.released,
            E_MILESTONE_ALREADY_RELEASED
        );

        let amount = milestone.amount;

        assert!(
            balance::value(&vault.balance) >= amount,
            E_INSUFFICIENT_BALANCE
        );

        // -----------------------------
        // Protocol Fee Calculation
        // -----------------------------

        let fee = protocol_fees::compute_fee(
            fee_config,
            amount,
            vault.tier
        );

        // Split full milestone amount
        let mut milestone_balance =
            balance::split(&mut vault.balance, amount);

        // Split fee
        let fee_balance =
            balance::split(&mut milestone_balance, fee);

        milestone.released = true;

        // -----------------------------
        // Deposit fee into Treasury
        // -----------------------------

        let fee_coin =
            coin::from_balance(fee_balance, ctx);

        treasury::deposit(
            cfg,
            treasury,
            fee_coin,
            ctx
        );

        // -----------------------------
        // Send net amount to recipient
        // -----------------------------

        let recipient_wallet =
            identity::get_owner(recipient_identity);

        transfer::public_transfer(
            coin::from_balance(milestone_balance, ctx),
            recipient_wallet
        );
    }

    /// ------------------------
    /// Close escrow
    /// ------------------------
    public fun close(
        cfg: &ProtocolConfig,
        cb: &circuit_breaker::CircuitBreaker,
        cap: &EscrowCap,
        vault: &mut Vault
    ) {

        protocol_governance::assert_protocol_active(cfg);

        assert!(
            !circuit_breaker::escrow_paused(cb),
            E_ESCROW_PAUSED
        );

        assert!(
            cap.campaign_id == vault.campaign_id,
            E_CAMPAIGN_MISMATCH
        );

        vault.closed = true;
    }
}
