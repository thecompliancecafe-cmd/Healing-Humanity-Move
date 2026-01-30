module healing_humanity::milestone_escrow {
    use sui::balance;
    use sui::coin::{self, Coin};
    use sui::sui::SUI;
    use sui::transfer;

    use healing_humanity::protocol_governance::ProtocolConfig;

    /// Escrow vault holding donated funds
    public struct Vault has key {
        id: object::UID,
        campaign_id: object::ID,
        balance: balance::Balance<SUI>,
    }

    /// Admin capability for releasing funds
    public struct EscrowAdminCap has key {
        id: object::UID,
    }

    /// Create escrow vault
    public fun create(
        campaign_id: object::ID,
        initial_coin: Coin<SUI>,
        ctx: &mut tx_context::TxContext
    ): (Vault, EscrowAdminCap) {
        let bal = coin::into_balance(initial_coin);

        let vault = Vault {
            id: object::new(ctx),
            campaign_id,
            balance: bal,
        };

        let cap = EscrowAdminCap {
            id: object::new(ctx),
        };

        (vault, cap)
    }

    /// Deposit funds into shared vault
    public fun deposit(
        vault: &mut Vault,
        coin_in: Coin<SUI>
    ) {
        let bal = coin::into_balance(coin_in);
        balance::join(&mut vault.balance, bal);
    }

    /// Release funds to recipient (governance-controlled)
    public fun release(
        _cap: &EscrowAdminCap,
        cfg: &ProtocolConfig,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut tx_context::TxContext
    ) {
        assert!(!protocol_governance::is_paused(cfg), 0);

        let bal_out = balance::split(&mut vault.balance, amount);
        let coin_out = coin::from_balance(bal_out, ctx);

        transfer::public_transfer(coin_out, recipient);
    }
}
