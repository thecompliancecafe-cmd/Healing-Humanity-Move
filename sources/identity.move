module healing_humanity::identity {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;
    use std::string;

    struct Identity has key {
        id: UID,
        name: string::String,
        wallet: address,
    }

    public fun create(
        name: string::String,
        wallet: address,
        ctx: &mut TxContext
    ): Identity {
        Identity {
            id: object::new(ctx),
            name,
            wallet,
        }
    }
}
