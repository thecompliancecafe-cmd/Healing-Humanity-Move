module healing_humanity::access_control {
    use sui::object::UID;
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::transfer;

    /// Main role registry object (shared)
    public struct Roles has key {
        id: UID,
        oracles: Table<address, bool>,
        compliance: Table<address, bool>,
        auditors: Table<address, bool>,
        treasury_signers: Table<address, bool>,
    }

    /// Admin capability (owned)
    public struct AdminCap has key {
        id: UID,
    }

    /// Initialize access control (callable once)
    public fun init(ctx: &mut TxContext): (Roles, AdminCap) {
        let roles = Roles {
            id: UID::new(ctx),
            oracles: Table::new(ctx),
            compliance: Table::new(ctx),
            auditors: Table::new(ctx),
            treasury_signers: Table::new(ctx),
        };

        let admin_cap = AdminCap {
            id: UID::new(ctx),
        };

        // Share Roles registry
        transfer::share_object(roles);

        // Return admin cap to caller
        (roles, admin_cap)
    }

    /// Add an oracle address (admin only)
    public fun add_oracle(
        _admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        if (!Table::contains(&roles.oracles, addr)) {
            Table::add(&mut roles.oracles, addr, true);
        }
    }

    /// Check if an address is an oracle
    public fun is_oracle(
        roles: &Roles,
        addr: address
    ): bool {
        Table::contains(&roles.oracles, addr)
    }
}
