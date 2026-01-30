module healing_humanity::compliance {
    use sui::table;

    /// Shared compliance registry
    public struct ComplianceRegistry has key {
        id: object::UID,
        approved: table::Table<address, bool>,
    }

    /// Admin capability for compliance approvals
    public struct ComplianceAdminCap has key {
        id: object::UID,
    }

    /// Package initialization (runs once at publish)
    /// NOTE: init must be internal and return ()
    fun init(ctx: &mut tx_context::TxContext) {
        let registry = ComplianceRegistry {
            id: object::new(ctx),
            approved: table::new(ctx),
        };

        let admin_cap = ComplianceAdminCap {
            id: object::new(ctx),
        };

        // Share registry globally
        transfer::share_object(registry);

        // Transfer admin cap to deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Approve an address as compliant (admin only)
    public fun approve(
        _admin: &ComplianceAdminCap,
        reg: &mut ComplianceRegistry,
        addr: address
    ) {
        if (!table::contains(&reg.approved, addr)) {
            table::add(&mut reg.approved, addr, true);
        }
    }

    /// Check if an address is compliant
    public fun is_compliant(
        reg: &ComplianceRegistry,
        addr: address
    ): bool {
        table::contains(&reg.approved, addr)
    }
}
