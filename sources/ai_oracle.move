module healing_humanity::ai_oracle {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct OracleRegistry has key {
        id: UID,
        oracles: vector<address>,
    }

    public entry fun init(ctx: &mut TxContext): OracleRegistry {
        OracleRegistry {
            id: object::new(ctx),
            oracles: vector::empty(),
        }
    }

    public fun add_oracle(reg: &mut OracleRegistry, oracle: address) {
        vector::push_back(&mut reg.oracles, oracle);
    }

    public fun is_oracle(reg: &OracleRegistry, addr: address): bool {
        vector::contains(&reg.oracles, &addr)
    }
}
