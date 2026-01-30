module healing_humanity::treasury {

    use sui::balance::Balance;
    use sui::coin::Coin;
    use sui::sui::SUI;

    /// Treasury object holding pooled funds
    public struct Treasury has key {
        id: UID,
        balance: Balance<SUI>,
    }

    /// Admin capability for treasury control
    public struct TreasuryCap has key {
        id: UID,
    }

    /// Create a new treasury
    public fun create(ctx: &mut TxContext): (Treasury, TreasuryCap) {
        let treasury = Treasury {
            id: sui::object::new(ctx),
            balance: sui::balance::zero<SUI>(),
        };

        let cap = TreasuryCap {
            id: sui::object::new(ctx),
        };

        // Treasury must be shared
        sui::transfer::share_object(treasury);

        (treasury, cap)
    }

    /// Deposit SUI into treasury
    public fun deposit(
        _cap: &TreasuryCap,
        treasury: &mut Treasury,
        coin: Coin<SUI>
    ) {
        let bal = sui::coin::into_balance(coin);
        sui::balance::join(&mut treasury.balance, bal);
    }

    /// Withdraw SUI from treasury
    public fun withdraw(
        _cap: &TreasuryCap,
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let bal = sui::balance::split(&mut treasury.balance, amount);
        let coin = sui::coin::from_balance(bal, ctx);
        sui::transfer::public_transfer(coin, recipient);
    }
}
