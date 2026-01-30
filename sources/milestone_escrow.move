module healing_humanity::milestone_escrow {

    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::transfer;

    use healing_humanity::protocol_governance;

    /// Vault holding escrowed funds
    public struct Vault has key {
        id: UID,
        campaign_id: ID,
        balance: Balance<SUI>,
    }

    /// Capability to release funds
    public struct EscrowCap has key {
        id: UID,
        campaign_id: ID,
    }

    /// Create a new escrow vault for a campaign
    public fun create(
        campaign_id: ID,
        ctx: &mut TxContext
    ): (Vault, EscrowCap) {
        let vault = Vault {
            id: object::new(ctx),
            campaign_id,
            balance: balance::zero<SUI>(),
        };

        let cap = EscrowCap {
            id: object::new(ctx),
            campaign_id,
        };

        // Vault must be shared
        transfer::share_object(vault);

        (vault, cap)
    }

    /// Deposit funds into escrow
    public fun deposit(
        vault: &mut Vault,
        coin_in: Coin<SUI>
    ) {
        let bal = coin::into_balance(coin_in);
        balance::join(&mut vault.balance, bal);
    }

    /// Release funds from escrow
    public fun release(
        cap: &EscrowCap,
        cfg: &protocol_governance::ProtocolConfig,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        // governance pause check
        assert!(
            !protocol_governance::is_paused(cfg),
            0
        );

        // ensure cap matches vault
        assert!(
            cap.campaign_id == vault.campaign_id,
            1
        );

        let bal_out = balance::split(&mut vault.balance, amount);
        let coin_out = coin::from_balance(bal_out, ctx);

        transfer::transfer(coin_out, recipient);
    }
}
