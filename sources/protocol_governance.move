module healing_humanity::protocol_governance {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::transfer;

    /// Global protocol configuration (shared object)
    public struct ProtocolConfig has key {
        id: UID,
        paused: bool,
        version: u64,
    }

    /// Governance admin capability
    public struct GovAdminCap has key {
        id: UID,
    }

    /// One-time initialization at package publish
    fun init(ctx: &mut TxContext) {
        let config = ProtocolConfig {
            id: UID::new(ctx),
            paused: false,
            version: 1,
        };

        let admin_cap = GovAdminCap {
            id: UID::new(ctx),
        };

        // Share global protocol configuration
        transfer::share_object(config);

        // Send admin capability to deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Emergency pause (governance only)
    public fun pause(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig
    ) {
        cfg.paused = true;
    }

    /// Resume protocol operations
    public fun unpause(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig
    ) {
        cfg.paused = false;
    }

    /// Upgrade version marker (used for migrations / audits)
    public fun bump_version(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig
    ) {
        cfg.version = cfg.version + 1;
    }

    /// Read-only helpers for other modules
    public fun is_paused(cfg: &ProtocolConfig): bool {
        cfg.paused
    }

    public fun version(cfg: &ProtocolConfig): u64 {
        cfg.version
    }
}
