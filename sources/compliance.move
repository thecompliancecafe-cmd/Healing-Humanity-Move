module healing_humanity::compliance {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::table::{Self, Table};
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

    /// Package initialization (runs once at publish)
    fun init(ctx: &mut TxContext) {
        let registry = ComplianceRegistry {
            id: UID::new(ctx),
            approved: Table::new(ctx),
        };

        let admin_cap = ComplianceAdminCap {
            id: UID::new(ctx),
        };

        // Make registry publicly readable / mutable
        transfer::share_object(registry);

        // Give admin permission to deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Approve an address as compliant (admin only)
    public fun approve(
        _admin: &ComplianceAdminCap,
        reg: &mut ComplianceRegistry,
        addr: address
    ) {
        Table::add(&mut reg.approved, addr, true);
    }

    /// Check if an address is compliant
    public fun is_compliant(
        reg: &ComplianceRegistry,
        addr: address
    ): bool {
        Table::contains(&reg.approved, addr)
    }
}
