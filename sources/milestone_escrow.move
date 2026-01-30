module healing_humanity::milestone_escrow {

    use sui::balance;
    use sui::coin;
    use sui::coin::Coin;
    use sui::sui::SUI;

    use healing_humanity::protocol_governance;
    use healing_humanity::protocol_governance::ProtocolConfig;

    /// Escrow vault holding campaign funds
    public struct Vault has key {
        id: sui::object::UID,
        campaign_id: sui::object::ID,
        balance: balance::Balance<SUI>,
    }

    /// Capability to release funds
    public struct EscrowCap has key {
        id: sui::object::UID,
    }

    /// Create a new escrow vault
    public fun create(
        campaign_id: sui::object::ID,
        ctx: &mut sui::tx_context::TxContext
    ): (Vault, EscrowCap) {
        (
            Vault {
                id: sui::object::new(ctx),
                campaign_id,
                balance: balance::zero<SUI>(),
            },
            EscrowCap {
                id: sui::object::new(ctx),
            }
        )
    }

    /// Deposit funds into escrow
    public fun deposit(
        vault: &mut Vault,
        coin_in: Coin<SUI>
    ) {
        let bal = coin::into_balance(coin_in);
        balance::join(&mut vault.balance, bal);
    }

    /// Release funds to recipient
    public fun release(
        _cap: &EscrowCap,
        cfg: &ProtocolConfig,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut sui::tx_context::TxContext
    ) {
        assert!(!protocol_governance::is_paused(cfg), 0);

        let bal_out = balance::split(&mut vault.balance, amount);
        let coin_out = coin::from_balance(bal_out, ctx);
        sui::transfer::public_transfer(coin_out, recipient);
    }
}
