module healing_humanity::ai_oracle {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::vector;

    struct OracleRegistry has key {
        id: UID,
        admins: vector<address>,
        oracles: vector<address>,
    }

    public fun init(admin: address, ctx: &mut TxContext): OracleRegistry {
        let mut admins = vector::empty<address>();
        vector::push_back(&mut admins, admin);

        OracleRegistry {
            id: object::new(ctx),
            admins,
            oracles: vector::empty(),
        }
    }

    public fun add_oracle(
        registry: &mut OracleRegistry,
        admin: &signer,
        oracle: address
    ) {
        assert!(vector::contains(&registry.admins, signer::address_of(admin)), 0);
        vector::push_back(&mut registry.oracles, oracle);
    }

    public fun is_oracle(registry: &OracleRegistry, addr: address): bool {
        vector::contains(&registry.oracles, addr)
    }
}
