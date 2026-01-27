module healing_humanity::access_control {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;
    use sui::table::Table;

    /// Main role registry object
    struct Roles has key {
        id: UID,
        oracles: Table<address, bool>,
        compliance: Table<address, bool>,
        auditors: Table<address, bool>,
        treasury_signers: Table<address, bool>,
    }

    /// Admin capability = permission
    struct AdminCap has key {
        id: UID,
    }

    /// Initializes roles + admin capability
    public fun init(ctx: &mut TxContext): (Roles, AdminCap) {
        (
            Roles {
                id: object::new(ctx),
                oracles: Table::new(ctx),
                compliance: Table::new(ctx),
                auditors: Table::new(ctx),
                treasury_signers: Table::new(ctx),
            },
            AdminCap { id: object::new(ctx) }
        )
    }

    public fun add_oracle(_: &AdminCap, roles: &mut Roles, addr: address) {
        Table::add(&mut roles.oracles, addr, true);
    }

    public fun is_oracle(roles: &Roles, addr: address): bool {
        Table::contains(&roles.oracles, addr)
    }
}
