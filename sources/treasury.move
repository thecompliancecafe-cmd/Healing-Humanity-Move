module healing_humanity::treasury {
    use sui::object;
    use sui::balance::{Balance};
    use sui::coin::{Coin};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::transfer;

    /// Treasury vault holding protocol funds (SUI)
    public struct Treasury has key {
        id: object::UID,
        balance: Balance<SUI>,
    }

    /// Create an empty treasury
    public fun create(ctx: &mut TxContext): Treasury {
        Treasury {
            id: object::new(ctx),
            balance: Balance::zero<SUI>(),
        }
    }

    /// Deposit SUI into treasury
    public fun deposit(
        treasury: &mut Treasury,
        coin_in: Coin<SUI>,
    ) {
        treasury.balance.join(coin::into_balance(coin_in));
    }

    /// Withdraw SUI from treasury
    public fun withdraw(
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let bal = treasury.balance.split(amount);
        let coin = coin::from_balance(bal, ctx);
        transfer::public_transfer(coin, recipient);
    }
}
