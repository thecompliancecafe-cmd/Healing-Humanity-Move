module healing_humanity::ai_oracle {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::table::{Self, Table};
    use sui::transfer;

    /// Registry of approved oracle addresses
    public struct OracleRegistry has key {
        id: UID,
        oracles: Table<address, bool>,
    }

    /// Capability to manage oracle registry
    public struct OracleAdminCap has key {
        id: UID,
    }

    /// Create registry + admin capability
    /// NOTE: This is NOT an `init` function (those are special in Sui)
    public fun create(
        ctx: &mut TxContext
    ): (OracleRegistry, OracleAdminCap) {
        let registry = OracleRegistry {
            id: object::new(ctx),
            oracles: table::new(ctx),
        };

        let cap = OracleAdminCap {
            id: object::new(ctx),
        };

        // Registry should be shared
        transfer::share_object(registry);

        (registry, cap)
    }

    /// Add a new oracle address
    public fun add_oracle(
        _cap: &OracleAdminCap,
        registry: &mut OracleRegistry,
        oracle: address
    ) {
        if (!table::contains(&registry.oracles, oracle)) {
            table::add(&mut registry.oracles, oracle, true);
        }
    }

    /// Check if an address is a valid oracle
    public fun is_oracle(
        registry: &OracleRegistry,
        oracle: address
    ): bool {
        table::contains(&registry.oracles, oracle)
    }
}
