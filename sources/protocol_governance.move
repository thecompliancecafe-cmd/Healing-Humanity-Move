module healing_humanity::protocol_governance {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;

    struct ProtocolConfig has key {
        id: UID,
        paused: bool,
        version: u64,
    }

    struct GovAdminCap has key {
        id: UID,
    }

    public fun init(ctx: &mut TxContext): (ProtocolConfig, GovAdminCap) {
        (
            ProtocolConfig {
                id: object::new(ctx),
                paused: false,
                version: 1,
            },
            GovAdminCap { id: object::new(ctx) }
        )
    }

    public fun pause(_: &GovAdminCap, cfg: &mut ProtocolConfig) {
        cfg.paused = true;
    }

    public fun unpause(_: &GovAdminCap, cfg: &mut ProtocolConfig) {
        cfg.paused = false;
    }

    public fun bump_version(_: &GovAdminCap, cfg: &mut ProtocolConfig) {
        cfg.version = cfg.version + 1;
    }
}
