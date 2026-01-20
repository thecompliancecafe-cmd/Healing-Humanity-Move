module healing_humanity::reputation {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::table::{Self, Table};

    struct ReputationBook has key {
        id: UID,
        scores: Table<address, u64>
    }

    public fun init(ctx: &mut TxContext): ReputationBook {
        ReputationBook {
            id: object::new(ctx),
            scores: table::new(ctx)
        }
    }

    public fun add_xp(book: &mut ReputationBook, user: address, xp: u64) {
        if (table::contains(&book.scores, user)) {
            let current = *table::borrow(&book.scores, user);
            table::remove(&mut book.scores, user);
            table::add(&mut book.scores, user, current + xp);
        } else {
            table::add(&mut book.scores, user, xp);
        }
    }

    public fun get_xp(book: &ReputationBook, user: address): u64 {
        *table::borrow(&book.scores, user)
    }
}
