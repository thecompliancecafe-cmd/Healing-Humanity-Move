module healing_humanity::milestone_escrow {

    use sui::object;
    use sui::object::{UID, ID};
    use sui::tx_context::TxContext;

    use sui::coin::{self, Coin};
    use sui::balance;
    use sui::balance::Balance;
    use sui::transfer;

    /// Escrow vault holding campaign funds
    public struct Vault has key {
        id: UID,
        campaign_id: ID,
        balance: Balance<sui::sui::SUI>,
    }

    /// Capability allowing controlled release
    public struct EscrowCap has key {
        id: UID,
        campaign_id: ID,
    }

    /// Create escrow vault and cap
    /// NOTE: vault is shared HERE (tests must not share it)
    public fun create(
        campaign_id: ID,
        initial_coin: Coin<sui::sui::SUI>,
        ctx: &mut TxContext
    ): (Vault, EscrowCap) {

        let bal = coin::into_balance(initial_coin);

        let vault = Vault {
            id: object::new(ctx),
            campaign_id,
            balance: bal,
        };

        let cap = EscrowCap {
            id: object::new(ctx),
            campaign_id,
        };

        // ✅ MUST be shared inside the module
        transfer::share_object(vault);

        (vault, cap)
    }

    /// Add funds to escrow
    public fun deposit(
        vault: &mut Vault,
        coin: Coin<sui::sui::SUI>
    ) {
        let bal = coin::into_balance(coin);
        balance::join(&mut vault.balance, bal);
    }

    /// Release funds to recipient
    public fun release(
        cap: &EscrowCap,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        // Authorization check
        assert!(cap.campaign_id == vault.campaign_id, 0);

        let bal_out = balance::split(&mut vault.balance, amount);

        let coin_out: Coin<sui::sui::SUI> =
            coin::from_balance(bal_out, ctx);

        // ✅ public transfer (allowed)
        transfer::public_transfer(coin_out, recipient);
    }
}
