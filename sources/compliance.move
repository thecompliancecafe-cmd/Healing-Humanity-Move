module healing_humanity::compliance {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::vector;

    struct ComplianceRegistry has key {
        id: UID,
        authority: address,
        approved_charities: vector<address>,
    }

    public fun init(authority: address, ctx: &mut TxContext): ComplianceRegistry {
        ComplianceRegistry {
            id: object::new(ctx),
            authority,
            approved_charities: vector::empty(),
        }
    }

    public fun approve_charity(
        registry: &mut ComplianceRegistry,
        authority: &signer,
        charity: address
    ) {
        assert!(signer::address_of(authority) == registry.authority, 0);
        vector::push_back(&mut registry.approved_charities, charity);
    }

    public fun is_compliant(registry: &ComplianceRegistry, charity: address): bool {
        vector::contains(&registry.approved_charities, charity)
    }
}
