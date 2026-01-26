module healing_humanity::reputation {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Reputation has key {
        id: UID,
        score: u64,
    }

    public entry fun init(ctx: &mut TxContext): Reputation {
        Reputation {
            id: object::new(ctx),
            score: 0,
        }
    }

    public fun increase(rep: &mut Reputation, value: u64) {
        rep.score = rep.score + value;
    }
}
