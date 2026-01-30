module healing_humanity::milestone_escrow {

    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::coin::{Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::transfer;

    /// Vault holding escrowed funds for a campaign
    public struct Vault has key {
        id: UID,
        campaign_id: ID,
        balance: Balance<SUI>,
    }

    /// Capability that allows releasing funds
    public struct EscrowCap has key {
        id: UID,
        campaign_id: ID,
    }

    /// Create a new escrow vault for a campaign
    /// The vault is shared inside this module (required by Sui)
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

        // Vault must be shared from inside its defining module
        transfer::share_object(vault);

        (vault, cap)
    }

    /// Deposit SUI into the escrow vault
    public fun deposit(
        vault: &mut Vault,
        coin: Coin<SUI>
    ) {
        let bal = balance::from_coin(coin);
        balance::join(&mut vault.balance, bal);
    }

    /// Release funds to a recipient
    public fun release(
        _cap: &EscrowCap,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let bal = balance::split(&mut vault.balance, amount);
        let coin = balance::to_coin(bal, ctx);
        transfer::public_transfer(coin, recipient);
    }
}
