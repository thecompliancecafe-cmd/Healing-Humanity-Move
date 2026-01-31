module healing_humanity::treasury {

    use sui::balance;
    use sui::coin::Coin;

    /// Treasury vault
    public struct Treasury has key {
        id: UID,
        balance: balance::Balance<sui::sui::SUI>,
    }

    /// Treasury admin capability
    public struct TreasuryCap has key {
        id: UID,
    }

    /// Create treasury
    public fun create(
        initial_coin: Coin<sui::sui::SUI>,
        ctx: &mut TxContext
    ): TreasuryCap {
        let treasury = Treasury {
            id: object::new(ctx),
            balance: sui::coin::into_balance(initial_coin),
        };

        let cap = TreasuryCap {
            id: object::new(ctx),
        };

        // Treasury must be shared
        transfer::share_object(treasury);

        cap
    }

    /// Deposit funds
    public fun deposit(
        _cap: &TreasuryCap,
        treasury: &mut Treasury,
        coin: Coin<sui::sui::SUI>
    ) {
        let bal = sui::coin::into_balance(coin);
        balance::join(&mut treasury.balance, bal);
    }

    /// Withdraw funds
    public fun withdraw(
        _cap: &TreasuryCap,
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let bal = balance::split(&mut treasury.balance, amount);
        let coin = sui::coin::from_balance(bal, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// View balance
    public fun balance(treasury: &Treasury): u64 {
        balance::value(&treasury.balance)
    }
}
