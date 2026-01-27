module healing_humanity::ai_oracle {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;
    use sui::table::Table;

    struct OracleRegistry has key {
        id: UID,
        oracles: Table<address, bool>,
    }

    struct OracleAdminCap has key {
        id: UID,
    }

    public fun init(ctx: &mut TxContext): (OracleRegistry, OracleAdminCap) {
        (
            OracleRegistry {
                id: object::new(ctx),
                oracles: Table::new(ctx),
            },
            OracleAdminCap { id: object::new(ctx) }
        )
    }

    public fun add_oracle(_: &OracleAdminCap, reg: &mut OracleRegistry, addr: address) {
        Table::add(&mut reg.oracles, addr, true);
    }

    public fun is_oracle(reg: &OracleRegistry, addr: address): bool {
        Table::contains(&reg.oracles, addr)
    }
}
