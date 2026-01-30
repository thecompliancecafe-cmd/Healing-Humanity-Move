module healing_humanity::milestone_escrow {

    use sui::object;
    use sui::object::{UID, ID};
    use sui::tx_context::TxContext;
    use sui::coin::{Coin};
    use sui::balance::{self, Balance};
    use sui::transfer;

    /// Escrow vault holding funds
    public struct Vault has key {
        id: UID,
        campaign_id: ID,
        balance: Balance<sui::sui::SUI>,
    }

    /// Capability to release funds
    public struct EscrowCap has key {
        id: UID,
        campaign_id: ID,
    }

    /// Create a new escrow vault
    public fun create(
        campaign_id: ID,
        coin: Coin<sui::sui::SUI>,
        ctx: &mut TxContext
    ): (Vault, EscrowCap) {
        let bal = sui::coin::into_balance(coin);

        let vault = Vault {
            id: object::new(ctx),
            campaign_id,
            balance: bal,
        };

        let cap = EscrowCap {
            id: object::new(ctx),
            campaign_id,
        };

        transfer::share_object(vault);

        (vault, cap)
    }

    /// Add more funds to the vault
    public fun deposit(
        vault: &mut Vault,
        coin: Coin<sui::sui::SUI>
    ) {
        let bal = sui::coin::into_balance(coin);
        balance::join(&mut vault.balance, bal);
    }

    /// Release funds to a recipient
    public fun release(
        cap: &EscrowCap,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(cap.campaign_id == vault.campaign_id, 0);

        let bal_out = balance::split(&mut vault.balance, amount);
        let coin_out = sui::coin::from_balance(bal_out, ctx);

        // ✅ FIXED LINE
        transfer::public_transfer(coin_out, recipient);
    }
}
