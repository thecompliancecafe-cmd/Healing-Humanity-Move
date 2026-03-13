module healing_humanity::ai_oracle {

    use sui::table::{Self, Table};

    use healing_humanity::identity::{Self, Identity};

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_ALREADY_ORACLE: u64 = 0;
    const E_IDENTITY_INACTIVE: u64 = 1;
    const E_INVALID_ROLE: u64 = 2;
    const E_NOT_VERIFIED: u64 = 3;

    /// -----------------------------
    /// Registry holding approved oracle identities
    /// -----------------------------
    public struct OracleRegistry has key {
        id: UID,
        oracles: Table<ID, bool>,
    }

    /// -----------------------------
    /// Admin capability
    /// -----------------------------
    public struct OracleAdminCap has key {
        id: UID,
    }

    /// -----------------------------
    /// Initialize registry
    /// -----------------------------
    fun init(ctx: &mut TxContext) {

        let registry = OracleRegistry {
            id: object::new(ctx),
            oracles: table::new(ctx),
        };

        transfer::share_object(registry);
    }

    /// -----------------------------
    /// Create admin capability
    /// -----------------------------
    public fun create_admin_cap(
        ctx: &mut TxContext
    ): OracleAdminCap {

        OracleAdminCap {
            id: object::new(ctx),
        }
    }

    /// -----------------------------
    /// Add Oracle Identity
    /// -----------------------------
    public fun add_oracle(
        _cap: &OracleAdminCap,
        registry: &mut OracleRegistry,
        oracle_identity: &Identity
    ) {

        // Ensure identity is active
        assert!(
            identity::is_active(oracle_identity),
            E_IDENTITY_INACTIVE
        );

        // Ensure identity is verified
        assert!(
            identity::is_verified(oracle_identity),
            E_NOT_VERIFIED
        );

        // Ensure identity role is oracle or AI agent
        let role = identity::get_role(oracle_identity);

        assert!(
            identity::is_ai(oracle_identity) || role == 5,
            E_INVALID_ROLE
        );

        let id = object::id(oracle_identity);

        assert!(
            !table::contains(&registry.oracles, id),
            E_ALREADY_ORACLE
        );

        table::add(&mut registry.oracles, id, true);
    }

    /// -----------------------------
    /// Check Oracle Identity
    /// -----------------------------
    public fun is_oracle_identity(
        registry: &OracleRegistry,
        oracle_identity: &Identity
    ): bool {

        table::contains(
            &registry.oracles,
            object::id(oracle_identity)
        )
    }

    /// -----------------------------
    /// Check Oracle Wallet
    /// -----------------------------
    public fun is_oracle(
        registry: &OracleRegistry,
        oracle_identity: &Identity,
        sender: address
    ): bool {

        if (!table::contains(&registry.oracles, object::id(oracle_identity))) {
            return false
        };

        identity::get_owner(oracle_identity) == sender
    }
}
