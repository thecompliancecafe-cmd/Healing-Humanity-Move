module healing_humanity::identity {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Identity has key {
        id: UID,
        owner: address,
    }

    public entry fun register(ctx: &mut TxContext): Identity {
        Identity {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
        }
    }
}
