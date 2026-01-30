module healing_humanity::treasury {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::coin::Coin;
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::transfer;

    /// Shared treasury holding protocol funds
    public struct Treasury has key {
        id: UID,
        balance: Balance<SUI>,
    }

    /// Create and share the treasury
    public fun create(ctx: &mut TxContext): Treasury {
        let treasury = Treasury {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
        };

        // Treasury must be shared from inside its module
        transfer::share_object(treasury);
        treasury
    }

    /// Deposit SUI into the treasury
    public fun deposit(
        treasury: &mut Treasury,
        coin: Coin<SUI>
    ) {
        let bal = balance::from_coin(coin);
        balance::join(&mut treasury.balance, bal);
    }

    /// Withdraw SUI from the treasury
    public fun withdraw(
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let bal = balance::split(&mut treasury.balance, amount);
        let coin = balance::to_coin(bal, ctx);
        transfer::public_transfer(coin, recipient);
    }
}
