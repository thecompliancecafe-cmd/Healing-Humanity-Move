module healing_humanity::milestone_escrow {

    use sui::balance::Balance;
    use sui::coin::Coin;

    /// Vault holding escrowed funds (SHARED object)
    public struct Vault has key {
        id: UID,
        campaign_id: ID,
        balance: Balance<sui::sui::SUI>,
    }

    /// Capability to release funds (OWNED object)
    public struct EscrowCap has key {
        id: UID,
        campaign_id: ID,
    }

    /// Create a new escrow vault
    public fun create(
        campaign_id: ID,
        initial_coin: Coin<sui::sui::SUI>,
        ctx: &mut TxContext
    ): EscrowCap {

        let balance = sui::coin::into_balance(initial_coin);

        let vault = Vault {
            id: object::new(ctx),
            campaign_id,
            balance,
        };

        let cap = EscrowCap {
            id: object::new(ctx),
            campaign_id,
        };

        transfer::share_object(vault);
        cap
    }

    public fun deposit(
        vault: &mut Vault,
        coin: Coin<sui::sui::SUI>
    ) {
        let bal = sui::coin::into_balance(coin);
        sui::balance::join(&mut vault.balance, bal);
    }

    public fun release(
        cap: &EscrowCap,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(cap.campaign_id == vault.campaign_id, 0);

        let bal_out = sui::balance::split(&mut vault.balance, amount);
        let coin_out = sui::coin::from_balance(bal_out, ctx);

        transfer::public_transfer(coin_out, recipient);
    }
}
