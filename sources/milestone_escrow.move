module healing_humanity::milestone_escrow {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Escrow has key {
        id: UID,
        released: bool,
    }

    public entry fun init(ctx: &mut TxContext): Escrow {
        Escrow {
            id: object::new(ctx),
            released: false,
        }
    }

    public fun release(e: &mut Escrow) {
        e.released = true;
    }
}
