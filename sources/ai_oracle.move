module healing_humanity::ai_oracle {

    use sui::table;
    use sui::table::Table;

    /// Registry holding approved oracle addresses
    public struct OracleRegistry has key {
        id: sui::object::UID,
        oracles: Table<address, bool>,
    }

    /// Admin capability for managing oracles
    public struct OracleAdminCap has key {
        id: sui::object::UID,
    }

    /// Create oracle registry
    public fun create(
        ctx: &mut sui::tx_context::TxContext
    ): (OracleRegistry, OracleAdminCap) {
        let registry = OracleRegistry {
            id: sui::object::new(ctx),
            oracles: table::new(ctx),
        };

        let cap = OracleAdminCap {
            id: sui::object::new(ctx),
        };

        sui::transfer::share_object(registry);
        (registry, cap)
    }

    /// Add a new oracle
    public fun add_oracle(
        _cap: &OracleAdminCap,
        registry: &mut OracleRegistry,
        oracle: address
    ) {
        if (!table::contains(&registry.oracles, oracle)) {
            table::add(&mut registry.oracles, oracle, true);
        }
    }

    /// Check if address is an approved oracle
    public fun is_oracle(
        registry: &OracleRegistry,
        oracle: address
    ): bool {
        table::contains(&registry.oracles, oracle)
    }
}
