module healing_humanity::ai_oracle {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::table::Table;
    use sui::transfer;

    /// Registry of approved AI oracle addresses (shared object)
    public struct OracleRegistry has key {
        id: UID,
        oracles: Table<address, bool>,
    }

    /// Capability to manage oracle registry
    public struct OracleAdminCap has key {
        id: UID,
    }

    /// One-time initialization at package publish
    fun init(ctx: &mut TxContext) {
        let registry = OracleRegistry {
            id: UID::new(ctx),
            oracles: Table::new(ctx),
        };

        let admin_cap = OracleAdminCap {
            id: UID::new(ctx),
        };

        // Share registry so other modules can verify oracles
        transfer::share_object(registry);

        // Give admin authority to deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Add a new trusted oracle (admin only)
    public fun add_oracle(
        _admin: &OracleAdminCap,
        reg: &mut OracleRegistry,
        addr: address
    ) {
        Table::add(&mut reg.oracles, addr, true);
    }

    /// Read-only check used by attestation / escrow modules
    public fun is_oracle(
        reg: &OracleRegistry,
        addr: address
    ): bool {
        Table::contains(&reg.oracles, addr)
    }
}
