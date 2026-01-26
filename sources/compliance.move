module healing_humanity::compliance {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct ComplianceRegistry has key {
        id: UID,
        approved: vector<address>,
    }

    public entry fun init(ctx: &mut TxContext): ComplianceRegistry {
        ComplianceRegistry {
            id: object::new(ctx),
            approved: vector::empty(),
        }
    }

    public fun approve(reg: &mut ComplianceRegistry, addr: address) {
        vector::push_back(&mut reg.approved, addr);
    }

    public fun is_approved(reg: &ComplianceRegistry, addr: address): bool {
        vector::contains(&reg.approved, &addr)
    }
}
