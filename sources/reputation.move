module healing_humanity::reputation {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;

    struct XP has key {
        id: UID,
        owner: address,
        xp: u64,
    }

    public fun award(
        owner: address,
        xp: u64,
        ctx: &mut TxContext
    ): XP {
        XP {
            id: object::new(ctx),
            owner,
            xp,
        }
    }
}
