module healing_humanity::protocol_governance {
    use sui::event;
    use sui::transfer;

    /// Global protocol configuration (shared object)
    public struct ProtocolConfig has key {
        id: object::UID,
        paused: bool,
        version: u64,
    }

    /// Governance admin capability
    public struct GovAdminCap has key {
        id: object::UID,
    }

    /// Governance events
    public struct ProtocolPaused has copy, drop {}
    public struct ProtocolUnpaused has copy, drop {}
    public struct VersionBumped has copy, drop {
        new_version: u64,
    }

    /// ✅ REQUIRED: internal init, returns ()
    fun init(ctx: &mut tx_context::TxContext) {
        let config = ProtocolConfig {
            id: object::new(ctx),
            paused: false,
            version: 1,
        };

        let admin_cap = GovAdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(config);
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Emergency pause
    public fun pause(_admin: &GovAdminCap, cfg: &mut ProtocolConfig) {
        if (!cfg.paused) {
            cfg.paused = true;
            event::emit(ProtocolPaused {});
        }
    }

    public fun unpause(_admin: &GovAdminCap, cfg: &mut ProtocolConfig) {
        if (cfg.paused) {
            cfg.paused = false;
            event::emit(ProtocolUnpaused {});
        }
    }

    public fun bump_version(_admin: &GovAdminCap, cfg: &mut ProtocolConfig) {
        cfg.version = cfg.version + 1;
        event::emit(VersionBumped { new_version: cfg.version });
    }

    public fun is_paused(cfg: &ProtocolConfig): bool {
        cfg.paused
    }

    public fun version(cfg: &ProtocolConfig): u64 {
        cfg.version
    }
}
