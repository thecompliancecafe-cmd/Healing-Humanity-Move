module healing_humanity::ai_oracle {

    use sui::object::{UID};
    use sui::tx_context::TxContext;
    use sui::table::Table;
    use sui::transfer;

    /// Registry holding approved oracle addresses
    public struct OracleRegistry has key {
        id: UID,
        oracles: Table<address, bool>,
    }

    /// Admin capability
    public struct OracleAdminCap has key {
        id: UID,
    }

    /// Initialize oracle registry (shared object)
    public fun init(ctx: &mut TxContext): OracleAdminCap {
        let registry = OracleRegistry {
            id: sui::object::new(ctx),
            oracles: Table::new(ctx),
        };

        let cap = OracleAdminCap {
            id: sui::object::new(ctx),
        };

        // Share registry globally
        transfer::share_object(registry);

        // ONLY return admin cap
        cap
    }

    /// Add a new oracle
    public fun add_oracle(
        _cap: &OracleAdminCap,
        registry: &mut OracleRegistry,
        oracle: address
    ) {
        assert!(
            !Table::contains(&registry.oracles, oracle),
            0
        );

        Table::add(&mut registry.oracles, oracle, true);
    }

    /// Check if address is oracle
    public fun is_oracle(
        registry: &OracleRegistry,
        oracle: address
    ): bool {
        Table::contains(&registry.oracles, oracle)
    }
}
