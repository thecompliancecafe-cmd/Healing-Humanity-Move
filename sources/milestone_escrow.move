module healing_humanity::milestone_escrow {
    use sui::object::{UID, ID, object};
    use sui::tx_context::TxContext;
    use sui::coin::{Coin};
    use sui::coin;
    use sui::transfer;
    use sui::event;

    /// Event: funds deposited
    struct FundsDeposited has copy, drop {
        vault_id: ID,
        amount: u64,
    }

    /// Event: funds released
    struct FundsReleased has copy, drop {
        vault_id: ID,
        to: address,
        amount: u64,
    }

    /// Escrow vault (SHARED OBJECT)
    struct Vault<T> has key {
        id: UID,
        campaign_id: ID,
        balance: Coin<T>,
    }

    /// Capability required to release funds
    struct EscrowAdminCap has key {
        id: UID,
    }

    /// Create vault + admin cap
    public fun create<T>(
        campaign_id: ID,
        initial_funds: Coin<T>,
        ctx: &mut TxContext
    ): (Vault<T>, EscrowAdminCap) {
        (
            Vault {
                id: object::new(ctx),
                campaign_id,
                balance: initial_funds,
            },
            EscrowAdminCap { id: object::new(ctx) }
        )
    }

    /// Share vault so anyone can deposit
    public fun share<T>(vault: Vault<T>) {
        transfer::share_object(vault);
    }

    /// Deposit funds into shared vault
    public fun deposit<T>(
        vault: &mut Vault<T>,
        coin_in: Coin<T>
    ) {
        let amount = coin::value(&coin_in);
        coin::merge(&mut vault.balance, coin_in);

        event::emit(FundsDeposited {
            vault_id: object::id(vault),
            amount,
        });
    }

    /// Release funds (ADMIN ONLY)
    public fun release<T>(
        _: &EscrowAdminCap,
        vault: &mut Vault<T>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let released = coin::split(&mut vault.balance, amount);

        transfer::transfer(released, recipient);

        event::emit(FundsReleased {
            vault_id: object::id(vault),
            to: recipient,
            amount,
        });
    }
}
