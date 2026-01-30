module healing_humanity::milestone_escrow {

    use sui::object::{UID, ID};
    use sui::tx_context::TxContext;

    use sui::balance;
    use sui::coin;
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::transfer;

    use healing_humanity::protocol_governance;
    use healing_humanity::protocol_governance::ProtocolConfig;

    /// Escrow vault holding SUI
    public struct Vault has key {
        id: UID,
        balance: balance::Balance<SUI>,
    }

    /// Capability to release funds
    public struct EscrowCap has key {
        id: UID,
    }

    /// Create a new escrow vault
    public fun create(
        _campaign_id: ID,
        ctx: &mut TxContext
    ): (Vault, EscrowCap) {
        (
            Vault {
                id: object::new(ctx),
                balance: balance::zero<SUI>(),
            },
            EscrowCap {
                id: object::new(ctx),
            }
        )
    }

    /// Deposit SUI into the vault
    public fun deposit(
        vault: &mut Vault,
        coin_in: Coin<SUI>
    ) {
        let bal = coin::into_balance(coin_in);
        balance::join(&mut vault.balance, bal);
    }

    /// Release funds if protocol is not paused
    public fun release(
        _cap: &EscrowCap,
        cfg: &ProtocolConfig,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(!protocol_governance::is_paused(cfg), 0);

        let bal_out = balance::split(&mut vault.balance, amount);
        let coin_out = coin::from_balance(bal_out, ctx);
        transfer::public_transfer(coin_out, recipient);
    }
}
