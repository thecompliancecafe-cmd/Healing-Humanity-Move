module healing_humanity::protocol_governance {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;

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

    /// Governance events
    public struct ProtocolPaused has copy, drop {}
    public struct ProtocolUnpaused has copy, drop {}
    public struct VersionBumped has copy, drop {
        new_version: u64,
    }

    /// Initialize protocol governance (callable once)
    public fun init(ctx: &mut TxContext): (ProtocolConfig, GovAdminCap) {
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

        // Return admin capability to caller
        (config, admin_cap)
    }

    /// Emergency pause (governance only)
    public fun pause(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig
    ) {
        if (!cfg.paused) {
            cfg.paused = true;
            event::emit(ProtocolPaused {});
        }
    }

    /// Resume protocol operations
    public fun unpause(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig
    ) {
        if (cfg.paused) {
            cfg.paused = false;
            event::emit(ProtocolUnpaused {});
        }
    }

    /// Upgrade version marker (used for audits & migrations)
    public fun bump_version(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig
    ) {
        cfg.version = cfg.version + 1;
        event::emit(VersionBumped {
            new_version: cfg.version,
        });
    }

    /// Read-only helpers for other modules
    public fun is_paused(cfg: &ProtocolConfig): bool {
        cfg.paused
    }

    public fun version(cfg: &ProtocolConfig): u64 {
        cfg.version
    }
}
