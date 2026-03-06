module healing_humanity::protocol_governance {

    use sui::event;
    use sui::clock::{Self, Clock};

    /// Error codes
    const E_ALREADY_PAUSED: u64 = 1;
    const E_NOT_PAUSED: u64 = 2;
    const E_PROTOCOL_PAUSED: u64 = 3;

    /// Global protocol configuration (shared object)
    public struct ProtocolConfig has key {
        id: UID,

        /// global state
        paused: bool,
        version: u64,

        /// protocol parameters
        protocol_fee_bps: u64,
        oracle_address: address,
        treasury_address: address
    }

    /// Governance admin capability
    public struct GovAdminCap has key {
        id: UID,
    }

    /// -----------------------------
    /// Events
    /// -----------------------------

    public struct ProtocolPaused has copy, drop {
        timestamp_ms: u64,
        admin: address
    }

    public struct ProtocolUnpaused has copy, drop {
        timestamp_ms: u64,
        admin: address
    }

    public struct VersionBumped has copy, drop {
        new_version: u64,
        timestamp_ms: u64,
        admin: address
    }

    public struct ProtocolFeeUpdated has copy, drop {
        new_fee_bps: u64,
        timestamp_ms: u64,
        admin: address
    }

    public struct OracleUpdated has copy, drop {
        new_oracle: address,
        timestamp_ms: u64,
        admin: address
    }

    public struct TreasuryUpdated has copy, drop {
        new_treasury: address,
        timestamp_ms: u64,
        admin: address
    }

    /// -----------------------------
    /// Initialization
    /// -----------------------------

    fun init(ctx: &mut TxContext) {

        let sender = tx_context::sender(ctx);

        let config = ProtocolConfig {
            id: object::new(ctx),

            paused: false,
            version: 1,

            protocol_fee_bps: 200,
            oracle_address: sender,
            treasury_address: sender
        };

        let admin_cap = GovAdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(config);
        transfer::transfer(admin_cap, sender);
    }

    /// -----------------------------
    /// Governance Actions
    /// -----------------------------

    public fun pause(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        clock: &Clock,
        ctx: &TxContext
    ) {
        assert!(!cfg.paused, E_ALREADY_PAUSED);

        cfg.paused = true;

        event::emit(ProtocolPaused {
            timestamp_ms: clock::timestamp_ms(clock),
            admin: tx_context::sender(ctx)
        });
    }

    public fun unpause(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        clock: &Clock,
        ctx: &TxContext
    ) {
        assert!(cfg.paused, E_NOT_PAUSED);

        cfg.paused = false;

        event::emit(ProtocolUnpaused {
            timestamp_ms: clock::timestamp_ms(clock),
            admin: tx_context::sender(ctx)
        });
    }

    public fun bump_version(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        clock: &Clock,
        ctx: &TxContext
    ) {
        cfg.version = cfg.version + 1;

        event::emit(VersionBumped {
            new_version: cfg.version,
            timestamp_ms: clock::timestamp_ms(clock),
            admin: tx_context::sender(ctx)
        });
    }

    public fun set_protocol_fee(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        new_fee_bps: u64,
        clock: &Clock,
        ctx: &TxContext
    ) {
        cfg.protocol_fee_bps = new_fee_bps;

        event::emit(ProtocolFeeUpdated {
            new_fee_bps,
            timestamp_ms: clock::timestamp_ms(clock),
            admin: tx_context::sender(ctx)
        });
    }

    public fun set_oracle_address(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        new_oracle: address,
        clock: &Clock,
        ctx: &TxContext
    ) {
        cfg.oracle_address = new_oracle;

        event::emit(OracleUpdated {
            new_oracle,
            timestamp_ms: clock::timestamp_ms(clock),
            admin: tx_context::sender(ctx)
        });
    }

    public fun set_treasury_address(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        new_treasury: address,
        clock: &Clock,
        ctx: &TxContext
    ) {
        cfg.treasury_address = new_treasury;

        event::emit(TreasuryUpdated {
            new_treasury,
            timestamp_ms: clock::timestamp_ms(clock),
            admin: tx_context::sender(ctx)
        });
    }

    /// -----------------------------
    /// Protocol Guards
    /// -----------------------------

    public fun assert_protocol_active(cfg: &ProtocolConfig) {
        assert!(!cfg.paused, E_PROTOCOL_PAUSED);
    }

    /// -----------------------------
    /// Read Helpers
    /// -----------------------------

    public fun is_paused(cfg: &ProtocolConfig): bool {
        cfg.paused
    }

    public fun version(cfg: &ProtocolConfig): u64 {
        cfg.version
    }

    public fun protocol_fee(cfg: &ProtocolConfig): u64 {
        cfg.protocol_fee_bps
    }

    public fun oracle(cfg: &ProtocolConfig): address {
        cfg.oracle_address
    }

    public fun treasury(cfg: &ProtocolConfig): address {
        cfg.treasury_address
    }
}
