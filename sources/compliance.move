module healing_humanity::compliance {

    use sui::table::{Self, Table};

    use healing_humanity::identity;
    use healing_humanity::identity::Identity;

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_IDENTITY_INACTIVE: u64 = 0;

    /// -----------------------------
    /// Shared compliance registry
    /// -----------------------------
    public struct ComplianceRegistry has key {
        id: UID,
        approved: Table<ID, bool>,
    }

    /// -----------------------------
    /// Admin capability
    /// -----------------------------
    public struct ComplianceAdminCap has key {
        id: UID,
    }

    /// -----------------------------
    /// Package initialization
    /// -----------------------------
    fun init(ctx: &mut TxContext) {

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

    /// -----------------------------
    /// Approve an identity as compliant
    /// -----------------------------
    public fun approve(
        _admin: &ComplianceAdminCap,
        reg: &mut ComplianceRegistry,
        identity_obj: &Identity
    ) {

        // Ensure identity is active
        assert!(
            identity::is_active(identity_obj),
            E_IDENTITY_INACTIVE
        );

        let id = object::id(identity_obj);

        if (!table::contains(&reg.approved, id)) {
            table::add(&mut reg.approved, id, true);
        }
    }

    /// -----------------------------
    /// Check if identity is compliant
    /// -----------------------------
    public fun is_compliant(
        reg: &ComplianceRegistry,
        identity_obj: &Identity
    ): bool {

        table::contains(
            &reg.approved,
            object::id(identity_obj)
        )
    }

    /// -----------------------------
    /// Wallet helper
    /// -----------------------------
    public fun wallet_is_compliant(
        reg: &ComplianceRegistry,
        identity_obj: &Identity
    ): bool {

        table::contains(
            &reg.approved,
            object::id(identity_obj)
        )
    }
}
