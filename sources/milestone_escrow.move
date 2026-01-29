module healing_humanity::milestone_escrow {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::event;

    /// Event: funds deposited
    public struct FundsDeposited has copy, drop {
        vault_id: UID,
        amount: u64,
    }

    /// Event: funds released
    public struct FundsReleased has copy, drop {
        vault_id: UID,
        recipient: address,
        amount: u64,
    }

    /// SHARED escrow vault (SUI only)
    public struct Vault has key {
        id: UID,
        campaign_id: UID,
        balance: Balance,
    }

    /// Capability required to release funds
    public struct EscrowAdminCap has key {
        id: UID,
    }

    /// Create vault + admin capability
    public fun create(
        campaign_id: UID,
        ctx: &mut TxContext
    ): (Vault, EscrowAdminCap) {
        (
            Vault {
                id: sui::object::new(ctx),
                campaign_id,
                balance: balance::zero(),
            },
            EscrowAdminCap {
                id: sui::object::new(ctx),
            }
        )
    }

    /// Share vault so anyone can deposit
    public fun share(vault: Vault) {
        transfer::share_object(vault);
    }

    /// Deposit SUI into vault
    public fun deposit(
        vault: &mut Vault,
        coin_in: Coin<sui::sui::SUI>
    ) {
        let amount = coin::value(&coin_in);
        balance::deposit(&mut vault.balance, coin_in);

        event::emit(FundsDeposited {
            vault_id: vault.id,
            amount,
        });
    }

    /// Release funds (ADMIN ONLY)
    public fun release(
        _: &EscrowAdminCap,
        vault: &mut Vault,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let coin_out = balance::withdraw(
            &mut vault.balance,
            amount,
            ctx
        );

        transfer::public_transfer(coin_out, recipient);

        event::emit(FundsReleased {
            vault_id: vault.id,
            recipient,
            amount,
        });
    }
}
