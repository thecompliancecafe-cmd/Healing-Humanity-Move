module healing_humanity::milestone_escrow {

    use sui::object::{UID, ID};
    use sui::tx_context::TxContext;
    use sui::coin::Coin;
    use sui::balance::Balance;
    use sui::sui::SUI;

    /// Escrow vault holding campaign funds
    public struct Vault has key {
        id: UID,
        campaign_id: ID,
        balance: Balance<SUI>,
    }

    /// Capability to authorize releases
    public struct EscrowCap has key {
        id: UID,
        campaign_id: ID,
    }

    /// Create a new escrow vault for a campaign
    /// Vault is shared INSIDE this function (correct pattern)
    public fun create(
        campaign_id: ID,
        initial_coin: Coin<SUI>,
        ctx: &mut TxContext
    ): (Vault, EscrowCap) {

        let balance = sui::coin::into_balance(initial_coin);

        let vault = Vault {
            id: sui::object::new(ctx),
            campaign_id,
            balance,
        };

        let cap = EscrowCap {
            id: sui::object::new(ctx),
            campaign_id,
        };

        // Share vault here (allowed)
        sui::transfer::share_object(vault);

        (vault, cap)
    }

    /// Deposit additional funds into escrow
    public fun deposit(
        vault: &mut Vault,
        coin: Coin<SUI>
    ) {
        let bal = sui::coin::into_balance(coin);
        sui::balance::join(&mut vault.balance, bal);
    }

    /// Release funds to recipient
    public fun release(
        cap: &EscrowCap,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        // Ensure correct campaign
        assert!(cap.campaign_id == vault.campaign_id, 0);

        let bal_out = sui::balance::split(&mut vault.balance, amount);
        let coin_out = sui::coin::from_balance(bal_out, ctx);

        // Public transfer (allowed)
        sui::transfer::public_transfer(coin_out, recipient);
    }
}
