module healing_humanity::protocol_governance {

    use sui::clock::{Self, Clock};
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use std::vector;
    use std::option;
    use healing_humanity::events;

    /// =========================
    /// ERRORS
    /// =========================
    const E_ALREADY_PAUSED: u64 = 1;
    const E_NOT_PAUSED: u64 = 2;
    const E_PROTOCOL_PAUSED: u64 = 3;
    const E_INVALID_FEE: u64 = 4;
    const E_INVALID_ADDRESS: u64 = 5;
    const E_NOT_ADMIN: u64 = 6;
    const E_TIMELOCK_NOT_READY: u64 = 7;

    /// =========================
    /// ACTION TYPES
    /// =========================
    const ACTION_SET_FEE: u8 = 1;
    const ACTION_SET_ORACLE: u8 = 2;
    const ACTION_SET_TREASURY: u8 = 3;
    const ACTION_PAUSE: u8 = 4;
    const ACTION_UNPAUSE: u8 = 5;
    const ACTION_VERSION_BUMP: u8 = 6;

    /// =========================
    /// STORAGE
    /// =========================
    public struct ProtocolConfig has key {
        id: UID,
        paused: bool,
        version: u64,
        protocol_fee_bps: u64,
        oracle_address: address,
        treasury_address: address,
        admins: vector<address>,
        timelock_ms: u64
    }

    public struct GovAdminCap has key {
        id: UID,
    }

    public struct GovernanceAction has key {
        id: UID,
        action_type: u8,
        value_u64: u64,
        value_address: address,
        execute_after: u64,
    }

    /// =========================
    /// INIT
    /// =========================
    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        let mut admins = vector::empty<address>();
        vector::push_back(&mut admins, sender);

        let config = ProtocolConfig {
            id: object::new(ctx),
            paused: false,
            version: 1,
            protocol_fee_bps: 200,
            oracle_address: sender,
            treasury_address: sender,
            admins,
            timelock_ms: 60000
        };

        let admin_cap = GovAdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(config);
        transfer::transfer(admin_cap, sender);
    }

    /// =========================
    /// INTERNAL ADMIN CHECK
    /// =========================
    fun assert_admin(cfg: &ProtocolConfig, sender: address) {
        let mut found = false;
        let len = vector::length(&cfg.admins);
        let mut i = 0;

        while (i < len) {
            if (*vector::borrow(&cfg.admins, i) == sender) {
                found = true;
            };
            i = i + 1;
        };

        assert!(found, E_NOT_ADMIN);
    }

    /// PUBLIC ADMIN CHECK
    public fun is_admin(cfg: &ProtocolConfig, addr: address): bool {
        let len = vector::length(&cfg.admins);
        let mut i = 0;

        while (i < len) {
            if (*vector::borrow(&cfg.admins, i) == addr) {
                return true
            };
            i = i + 1;
        };

        false
    }

    /// =========================
    /// QUEUE GOVERNANCE ACTION
    /// =========================
    public fun queue_action(
        _admin: &GovAdminCap,
        cfg: &ProtocolConfig,
        action_type: u8,
        value_u64: u64,
        value_address: address,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        let sender = tx_context::sender(ctx);
        assert_admin(cfg, sender);

        let execute_after = clock::timestamp_ms(clock) + cfg.timelock_ms;

        let action = GovernanceAction {
            id: object::new(ctx),
            action_type,
            value_u64,
            value_address,
            execute_after,
        };

        let id = object::id(&action); // correct
        transfer::share_object(action);
        id
    }

    /// =========================
    /// EXECUTE GOVERNANCE ACTION
    /// =========================
    public fun execute_action(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        action: &mut GovernanceAction,
        clock: &Clock,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert_admin(cfg, sender);

        assert!(
            clock::timestamp_ms(clock) >= action.execute_after,
            E_TIMELOCK_NOT_READY
        );

        let id = object::id(action); // ✅ FIXED (no extra borrow)
        let action_id = option::some(id);

        /// SET FEE
        if (action.action_type == ACTION_SET_FEE) {
            assert!(action.value_u64 <= 10_000, E_INVALID_FEE);
            cfg.protocol_fee_bps = action.value_u64;

            events::emit_protocol_fee_updated(
                action.value_u64,
                sender,
                action_id,
                clock
            );
        };

        /// SET ORACLE
        if (action.action_type == ACTION_SET_ORACLE) {
            assert!(action.value_address != @0x0, E_INVALID_ADDRESS);
            cfg.oracle_address = action.value_address;

            events::emit_oracle_updated(
                action.value_address,
                sender,
                action_id,
                clock
            );
        };

        /// SET TREASURY
        if (action.action_type == ACTION_SET_TREASURY) {
            assert!(action.value_address != @0x0, E_INVALID_ADDRESS);
            cfg.treasury_address = action.value_address;

            events::emit_treasury_updated(
                action.value_address,
                sender,
                action_id,
                clock
            );
        };

        /// PAUSE
        if (action.action_type == ACTION_PAUSE) {
            cfg.paused = true;

            events::emit_protocol_paused(
                sender,
                b"timelock",
                action_id,
                clock
            );
        };

        /// UNPAUSE
        if (action.action_type == ACTION_UNPAUSE) {
            cfg.paused = false;

            events::emit_protocol_unpaused(
                sender,
                action_id,
                clock
            );
        };

        /// VERSION BUMP
        if (action.action_type == ACTION_VERSION_BUMP) {
            cfg.version = cfg.version + 1;

            events::emit_version_bumped(
                cfg.version,
                sender,
                action_id,
                clock
            );
        };
    }

    /// =========================
    /// IMMEDIATE ACTIONS
    /// =========================
    public fun pause(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        reason: vector<u8>,
        clock: &Clock,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert_admin(cfg, sender);
        assert!(!cfg.paused, E_ALREADY_PAUSED);

        cfg.paused = true;

        events::emit_protocol_paused(
            sender,
            reason,
            option::none(),
            clock
        );
    }

    public fun unpause(
        _admin: &GovAdminCap,
        cfg: &mut ProtocolConfig,
        clock: &Clock,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert_admin(cfg, sender);
        assert!(cfg.paused, E_NOT_PAUSED);

        cfg.paused = false;

        events::emit_protocol_unpaused(
            sender,
            option::none(),
            clock
        );
    }

    /// =========================
    /// HELPERS
    /// =========================
    public fun assert_protocol_active(cfg: &ProtocolConfig) {
        assert!(!cfg.paused, E_PROTOCOL_PAUSED);
    }

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
