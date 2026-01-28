module healing_humanity::access_control {
    use sui::object::UID;
    use sui::tx_context::TxContext;
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

    /// Package initialization
    /// This runs ONCE at publish time
    fun init(ctx: &mut TxContext) {
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

        // Share the Roles object so everyone can read it
        transfer::share_object(roles);

        // Give AdminCap to the publisher
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Add an oracle address (admin only)
    public fun add_oracle(
        _admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        Table::add(&mut roles.oracles, addr, true);
    }

    /// Check if an address is an oracle
    public fun is_oracle(
        roles: &Roles,
        addr: address
    ): bool {
        Table::contains(&roles.oracles, addr)
    }
}
