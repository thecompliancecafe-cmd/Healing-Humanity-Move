module healing_humanity::ai_oracle {

    /// Shared registry of approved AI oracles
    public struct OracleRegistry has key {
        id: sui::object::UID,
        oracles: sui::table::Table<address, bool>,
    }

    /// Admin capability for oracle management
    public struct OracleAdminCap has key {
        id: sui::object::UID,
    }

    /// One-time initializer
    fun init(ctx: &mut sui::tx_context::TxContext) {
        let registry = OracleRegistry {
            id: sui::object::new(ctx),
            oracles: sui::table::new(ctx),
        };

        let admin_cap = OracleAdminCap {
            id: sui::object::new(ctx),
        };

        // Share registry globally
        sui::transfer::share_object(registry);

        // Return admin cap to sender
        sui::transfer::transfer(admin_cap, sui::tx_context::sender(ctx));
    }

    /// Add a new oracle (admin only)
    public fun add_oracle(
        _admin: &OracleAdminCap,
        reg: &mut OracleRegistry,
        addr: address
    ) {
        if (!sui::table::contains(&reg.oracles, addr)) {
            sui::table::add(&mut reg.oracles, addr, true);
        }
    }

    /// Check oracle approval
    public fun is_oracle(
        reg: &OracleRegistry,
        addr: address
    ): bool {
        sui::table::contains(&reg.oracles, addr)
    }
}
