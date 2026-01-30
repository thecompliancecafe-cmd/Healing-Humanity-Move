module healing_humanity::treasury {
    use sui::object;
    use sui::tx_context::TxContext;

    use sui::balance;
    use sui::balance::Balance;

    use sui::coin;
    use sui::coin::Coin;

    use sui::sui::SUI;
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
            balance: balance::zero<SUI>(),
        }
    }

    /// Deposit SUI into treasury
    public fun deposit(
        treasury: &mut Treasury,
        coin_in: Coin<SUI>
    ) {
        let bal = coin::into_balance(coin_in);
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
        let coin = coin::from_balance(bal, ctx);
        transfer::public_transfer(coin, recipient);
    }
}
