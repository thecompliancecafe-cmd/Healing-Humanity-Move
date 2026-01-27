module healing_humanity::treasury {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;
    use sui::coin::Coin;

    struct Treasury<T> has key {
        id: UID,
        balance: Coin<T>,
    }

    public fun create<T>(
        coin: Coin<T>,
        ctx: &mut TxContext
    ): Treasury<T> {
        Treasury {
            id: object::new(ctx),
            balance: coin,
        }
    }
}
