module healing_humanity::treasury {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;

    /// Treasury vault holding protocol funds (SUI)
    public struct Treasury has key {
        id: UID,
        balance: Balance,
    }

    /// Create an empty treasury
    public fun create(ctx: &mut TxContext): Treasury {
        Treasury {
            id: UID::new(ctx),
            balance: balance::zero(),
        }
    }

    /// Deposit SUI into treasury
    public fun deposit(
        treasury: &mut Treasury,
        coin_in: Coin<sui::sui::SUI>
    ) {
        balance::deposit(&mut treasury.balance, coin_in);
    }

    /// Withdraw SUI from treasury
    /// (access control / multisig will be layered on top later)
    public fun withdraw(
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let coin_out = balance::withdraw(
            &mut treasury.balance,
            amount,
            ctx
        );

        transfer::public_transfer(coin_out, recipient);
    }
}
