module healing_humanity::milestone_escrow {

    use sui::coin::Coin;
    use sui::balance::Balance;

    /// ------------------------
    /// Errors
    /// ------------------------
    const E_CAMPAIGN_MISMATCH: u64 = 0;
    const E_MILESTONE_INVALID: u64 = 1;
    const E_MILESTONE_ALREADY_RELEASED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_ESCROW_CLOSED: u64 = 4;

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
    /// Create escrow with milestones
    /// ENTRY — RETURNS NOTHING
    /// ------------------------
    public entry fun create(
        campaign_id: ID,
        initial_coin: Coin<sui::sui::SUI>,
        milestone_amounts: vector<u64>,
        ctx: &mut TxContext
    ) {
        let balance = sui::coin::into_balance(initial_coin);
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
            id: sui::object::new(ctx),
            campaign_id,
            balance,
            milestones,
            closed: false,
        };

        let cap = EscrowCap {
            id: sui::object::new(ctx),
            campaign_id,
        };

        // Share the vault
        sui::transfer::share_object(vault);

        // Transfer EscrowCap to transaction sender
        sui::transfer::transfer(cap, sui::tx_context::sender(ctx));
    }

    /// ------------------------
    /// Deposit additional funds
    /// ------------------------
    public entry fun deposit(
        vault: &mut Vault,
        coin: Coin<sui::sui::SUI>
    ) {
        assert!(!vault.closed, E_ESCROW_CLOSED);
        sui::balance::join(
            &mut vault.balance,
            sui::coin::into_balance(coin)
        );
    }

    /// ------------------------
    /// Release a milestone
    /// ------------------------
    public entry fun release_milestone(
        cap: &EscrowCap,
        vault: &mut Vault,
        milestone_id: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(!vault.closed, E_ESCROW_CLOSED);
        assert!(cap.campaign_id == vault.campaign_id, E_CAMPAIGN_MISMATCH);

        let len = vector::length(&vault.milestones);
        assert!(milestone_id < len, E_MILESTONE_INVALID);

        let milestone = vector::borrow_mut(&mut vault.milestones, milestone_id);
        assert!(!milestone.released, E_MILESTONE_ALREADY_RELEASED);

        let amount = milestone.amount;
        assert!(
            sui::balance::value(&vault.balance) >= amount,
            E_INSUFFICIENT_BALANCE
        );

        let bal_out = sui::balance::split(&mut vault.balance, amount);
        milestone.released = true;

        sui::transfer::public_transfer(
            sui::coin::from_balance(bal_out, ctx),
            recipient
        );
    }

    /// ------------------------
    /// Close escrow
    /// ------------------------
    public entry fun close(
        cap: &EscrowCap,
        vault: &mut Vault
    ) {
        assert!(cap.campaign_id == vault.campaign_id, E_CAMPAIGN_MISMATCH);
        vault.closed = true;
    }
}
