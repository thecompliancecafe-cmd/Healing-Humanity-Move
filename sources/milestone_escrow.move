module healing_humanity::milestone_escrow {

    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};

    use healing_humanity::protocol_fees;
    use healing_humanity::treasury;
    use healing_humanity::treasury::Treasury;
    use healing_humanity::circuit_breaker;

    /// ------------------------
    /// Errors
    /// ------------------------
    const E_CAMPAIGN_MISMATCH: u64 = 0;
    const E_MILESTONE_INVALID: u64 = 1;
    const E_MILESTONE_ALREADY_RELEASED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_ESCROW_CLOSED: u64 = 4;
    const E_ESCROW_PAUSED: u64 = 5;

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
    }

    /// ------------------------
    /// Create escrow
    /// ------------------------
    public fun create(
        campaign_id: ID,
        tier: u8,
        initial_coin: Coin<sui::sui::SUI>,
        milestone_amounts: vector<u64>,
        ctx: &mut TxContext
    ) {
        let balance = coin::into_balance(initial_coin);
        let mut milestones = vector::empty<Milestone>();

        let mut i = 0;
        let len = vector::length(&milestone_amounts);

        while (i < len) {
            let amt = *vector::borrow(&milestone_amounts, i);
            vector::push_back(
                &mut milestones,
                Milestone { id: i, amount: amt, released: false }
            );
            i = i + 1;
        };

        let vault = Vault {
            id: object::new(ctx),
            campaign_id,
            tier,
            balance,
            milestones,
            closed: false,
        };

        let cap = EscrowCap {
            id: object::new(ctx),
            campaign_id,
        };

        transfer::share_object(vault);
        transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// ------------------------
    /// Deposit funds
    /// ------------------------
    public fun deposit(
        cb: &circuit_breaker::CircuitBreaker,
        vault: &mut Vault,
        coin: Coin<sui::sui::SUI>
    ) {
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
        cb: &circuit_breaker::CircuitBreaker,
        fee_config: &protocol_fees::ProtocolFeeConfig,
        cap: &EscrowCap,
        vault: &mut Vault,
        milestone_id: u64,
        recipient: address,
        treasury: &mut Treasury,
        ctx: &mut TxContext
    ) {
        assert!(
            !circuit_breaker::escrow_paused(cb),
            E_ESCROW_PAUSED
        );

        assert!(!vault.closed, E_ESCROW_CLOSED);
        assert!(cap.campaign_id == vault.campaign_id, E_CAMPAIGN_MISMATCH);

        let len = vector::length(&vault.milestones);
        assert!(milestone_id < len, E_MILESTONE_INVALID);

        let milestone = vector::borrow_mut(&mut vault.milestones, milestone_id);
        assert!(!milestone.released, E_MILESTONE_ALREADY_RELEASED);

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
        let mut milestone_balance = balance::split(&mut vault.balance, amount);

        // Split fee
        let fee_balance = balance::split(&mut milestone_balance, fee);

        milestone.released = true;

        // -----------------------------
        // Deposit fee into Treasury
        // -----------------------------

        let fee_coin = coin::from_balance(fee_balance, ctx);

        treasury::deposit(
            treasury,
            fee_coin,
            ctx
        );

        // -----------------------------
        // Send net amount to recipient
        // -----------------------------

        transfer::public_transfer(
            coin::from_balance(milestone_balance, ctx),
            recipient
        );
    }

    /// ------------------------
    /// Close escrow
    /// ------------------------
    public fun close(
        cb: &circuit_breaker::CircuitBreaker,
        cap: &EscrowCap,
        vault: &mut Vault
    ) {
        assert!(
            !circuit_breaker::escrow_paused(cb),
            E_ESCROW_PAUSED
        );

        assert!(cap.campaign_id == vault.campaign_id, E_CAMPAIGN_MISMATCH);
        vault.closed = true;
    }
}
