module healing_humanity::protocol_governance {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Governance has key {
        id: UID,
        version: u64,
    }

    public entry fun init(ctx: &mut TxContext): Governance {
        Governance {
            id: object::new(ctx),
            version: 1,
        }
    }
}
