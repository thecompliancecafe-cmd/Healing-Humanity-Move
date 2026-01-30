module healing_humanity::ai_oracle {

    use sui::table;
    use sui::table::Table;

    /// Registry holding approved oracle addresses
    public struct OracleRegistry has key {
        id: UID,
        oracles: Table<address, bool>,
    }

    /// Admin capability
    public struct OracleAdminCap has key {
        id: UID,
    }

    fun init(ctx: &mut TxContext) {
        let registry = OracleRegistry {
            id: sui::object::new(ctx),
            oracles: table::new(ctx),
        };

        sui::transfer::share_object(registry);
    }

    public fun create_admin_cap(ctx: &mut TxContext): OracleAdminCap {
        OracleAdminCap {
            id: sui::object::new(ctx),
        }
    }

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

    public fun is_oracle(
        registry: &OracleRegistry,
        oracle: address
    ): bool {
        table::contains(&registry.oracles, oracle)
    }
}
