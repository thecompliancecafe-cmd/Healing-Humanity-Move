module healing_humanity::treasury {

    use sui::object;
    use sui::object::UID;
    use sui::tx_context::TxContext;

    use sui::coin::{self, Coin};
    use sui::balance;
    use sui::balance::Balance;
    use sui::transfer;

    /// Treasury holding pooled SUI
    public struct Treasury has key {
        id: UID,
        balance: Balance<sui::sui::SUI>,
    }

    /// Create a new treasury
    public fun create(ctx: &mut TxContext): Treasury {
        Treasury {
            id: object::new(ctx),
            balance: balance::zero<sui::sui::SUI>(),
        }
    }

    /// Deposit SUI into treasury
    public fun deposit(
        treasury: &mut Treasury,
        coin: Coin<sui::sui::SUI>
    ) {
        let bal = coin::into_balance(coin);
        balance::join(&mut treasury.balance, bal);
    }

    /// Withdraw SUI from treasury
    public fun withdraw(
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let bal = balance::split(&mut treasury.balance, amount);

        let coin_out: Coin<sui::sui::SUI> =
            coin::from_balance(bal, ctx);

        transfer::public_transfer(coin_out, recipient);
    }
}
