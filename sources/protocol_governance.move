module healing_humanity::protocol_governance {
    use sui::object::{self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;

    /// Global protocol configuration (shared object)
    public struct ProtocolConfig has key {
        id: UID,
        paused: bool,
        version: u64,
    }

    /// Governance admin capability (owned)
    public struct GovAdminCap has key {
        id: UID,
    }

    /// Governance events
    public struct ProtocolPaused has copy, drop {}
    public struct ProtocolUnpaused has copy, drop {}
    public struct VersionBumped has copy, drop {
        new_version: u64,
    }

    /// Module initializer (runs ONCE at publish time)
    fun init(ctx: &mut TxContext) {
        let config = ProtocolConfig {
            id: object::new(ctx),
            paused: false,
            version: 1,
        };

        let admin_cap = GovAdminCap {
            id: object::new(ctx),
        };

        // Share global protocol configuration
        transfer::share_object(config);

        // Transfer governance authority to publisher
        transfer::transfer(admin_cap, tx_context::sender(ctx));
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

    /// Upgrade version marker
    public fun bump_version(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig
    ) {
        cfg.version = cfg.version + 1;
        event::emit(VersionBumped {
            new_version: cfg.version,
        });
    }

    /// Read-only helpers
    public fun is_paused(cfg: &ProtocolConfig): bool {
        cfg.paused
    }

    public fun version(cfg: &ProtocolConfig): u64 {
        cfg.version
    }

    /* =========================
       TESTING ONLY
       ========================= */

    #[test_only]
    public fun init_for_testing(
        ctx: &mut TxContext
    ): (ProtocolConfig, GovAdminCap) {
        (
            ProtocolConfig {
                id: object::new(ctx),
                paused: false,
                version: 1,
            },
            GovAdminCap {
                id: object::new(ctx),
            }
        )
    }
}
