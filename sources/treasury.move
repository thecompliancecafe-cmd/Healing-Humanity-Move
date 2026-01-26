module healing_humanity::treasury {
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::TxContext;

    struct Treasury has key {
        id: UID,
        funds: Balance<SUI>,
    }

    public entry fun init(ctx: &mut TxContext): Treasury {
        Treasury {
            id: object::new(ctx),
            funds: balance::zero(),
        }
    }
}
