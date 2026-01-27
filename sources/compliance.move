module healing_humanity::compliance {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;
    use sui::table::Table;

    struct ComplianceRegistry has key {
        id: UID,
        approved: Table<address, bool>,
    }

    struct ComplianceAdminCap has key {
        id: UID,
    }

    public fun init(ctx: &mut TxContext): (ComplianceRegistry, ComplianceAdminCap) {
        (
            ComplianceRegistry {
                id: object::new(ctx),
                approved: Table::new(ctx),
            },
            ComplianceAdminCap { id: object::new(ctx) }
        )
    }

    public fun approve(_: &ComplianceAdminCap, reg: &mut ComplianceRegistry, addr: address) {
        Table::add(&mut reg.approved, addr, true);
    }

    public fun is_compliant(reg: &ComplianceRegistry, addr: address): bool {
        Table::contains(&reg.approved, addr)
    }
}
