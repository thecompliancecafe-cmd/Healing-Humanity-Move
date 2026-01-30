module healing_humanity::ai_oracle {

    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::table;
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

    /// Module initializer (runs at publish time)
    fun init(ctx: &mut TxContext) {
        let registry = OracleRegistry {
            id: sui::object::new(ctx),
            oracles: table::new(ctx),
        };

        transfer::share_object(registry);
    }

    /// Create an admin capability (call AFTER publish)
    public fun create_admin_cap(ctx: &mut TxContext): OracleAdminCap {
        OracleAdminCap {
            id: sui::object::new(ctx),
        }
    }

    /// Add a new oracle
    public fun add_oracle(
        _cap: &OracleAdminCap,
        registry: &mut OracleRegistry,
        oracle: address
    ) {
        assert!(
            !table::contains(&registry.oracles, oracle),
            0
        );

        table::add(&mut registry.oracles, oracle, true);
    }

    /// Check if address is oracle
    public fun is_oracle(
        registry: &OracleRegistry,
        oracle: address
    ): bool {
        table::contains(&registry.oracles, oracle)
    }
}
