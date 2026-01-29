module healing_humanity::compliance {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::table::Table;
    use sui::transfer;

    /// Shared compliance registry
    public struct ComplianceRegistry has key {
        id: UID,
        approved: Table<address, bool>,
    }

    /// Admin capability for compliance approvals
    public struct ComplianceAdminCap has key {
        id: UID,
    }

    /// Initialize compliance registry (callable once)
    public fun init(ctx: &mut TxContext): (ComplianceRegistry, ComplianceAdminCap) {
        let registry = ComplianceRegistry {
            id: UID::new(ctx),
            approved: Table::new(ctx),
        };

        let admin_cap = ComplianceAdminCap {
            id: UID::new(ctx),
        };

        // Share registry so it can be accessed globally
        transfer::share_object(registry);

        // Return admin capability to caller
        (registry, admin_cap)
    }

    /// Approve an address as compliant (admin only)
    public fun approve(
        _admin: &ComplianceAdminCap,
        reg: &mut ComplianceRegistry,
        addr: address
    ) {
        if (!Table::contains(&reg.approved, addr)) {
            Table::add(&mut reg.approved, addr, true);
        }
    }

    /// Check if an address is compliant
    public fun is_compliant(
        reg: &ComplianceRegistry,
        addr: address
    ): bool {
        Table::contains(&reg.approved, addr)
    }
}
