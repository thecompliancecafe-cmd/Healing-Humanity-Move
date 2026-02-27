module healing_humanity::circuit_breaker {

    use sui::table::{Self, Table};
    use sui::event;
    use sui::clock;

    /// Error Codes
    const E_ALREADY_PAUSED: u64 = 0;
    const E_NOT_PAUSED: u64 = 1;
    const E_NOT_AUTHORIZED: u64 = 2;

    /// Shared Circuit Breaker Object
    public struct CircuitBreaker has key {
        id: UID,
        paused: bool,
        pause_campaigns: bool,
        pause_escrow: bool,
        pause_withdrawals: bool,
        last_pause_timestamp: u64,
        last_pause_reason: vector<u8>,
        admins: Table<address, bool>,
    }

    /// Admin Capability
    public struct CircuitAdminCap has key {
        id: UID,
    }

    /// Events
    public struct ProtocolPaused has copy, drop {
        timestamp: u64,
        reason: vector<u8>,
    }

    public struct ProtocolUnpaused has copy, drop {
        timestamp: u64,
    }

    /// Init at publish
    fun init(ctx: &mut TxContext) {

        let mut admins = table::new(ctx);

        let sender = tx_context::sender(ctx);
        table::add(&mut admins, sender, true);

        let breaker = CircuitBreaker {
            id: object::new(ctx),
            paused: false,
            pause_campaigns: false,
            pause_escrow: false,
            pause_withdrawals: false,
            last_pause_timestamp: 0,
            last_pause_reason: b"",
            admins,
        };

        let admin_cap = CircuitAdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(breaker);
        transfer::transfer(admin_cap, sender);
    }

    /// INTERNAL AUTH CHECK
    fun assert_admin(cb: &CircuitBreaker, sender: address) {
        let exists = table::contains(&cb.admins, sender);
        assert!(exists, E_NOT_AUTHORIZED);
    }

    /// Add new admin
    public fun add_admin(
        _admin_cap: &CircuitAdminCap,
        cb: &mut CircuitBreaker,
        new_admin: address,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert_admin(cb, sender);

        if (!table::contains(&cb.admins, new_admin)) {
            table::add(&mut cb.admins, new_admin, true);
        }
    }

    /// GLOBAL PAUSE
    public fun pause(
        _cap: &CircuitAdminCap,
        cb: &mut CircuitBreaker,
        reason: vector<u8>,
        clk: &clock::Clock,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert_admin(cb, sender);

        assert!(!cb.paused, E_ALREADY_PAUSED);

        cb.paused = true;
        cb.last_pause_timestamp = clock::timestamp_ms(clk);
        cb.last_pause_reason = reason;

        event::emit(ProtocolPaused {
            timestamp: cb.last_pause_timestamp,
            reason: cb.last_pause_reason,
        });
    }

    /// GLOBAL UNPAUSE
    public fun unpause(
        _cap: &CircuitAdminCap,
        cb: &mut CircuitBreaker,
        clk: &clock::Clock,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert_admin(cb, sender);

        assert!(cb.paused, E_NOT_PAUSED);

        cb.paused = false;

        event::emit(ProtocolUnpaused {
            timestamp: clock::timestamp_ms(clk),
        });
    }

    /// PARTIAL PAUSE
    public fun set_partial_pause(
        _cap: &CircuitAdminCap,
        cb: &mut CircuitBreaker,
        campaigns: bool,
        escrow: bool,
        withdrawals: bool,
        ctx: &TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert_admin(cb, sender);

        cb.pause_campaigns = campaigns;
        cb.pause_escrow = escrow;
        cb.pause_withdrawals = withdrawals;
    }

    /// READ FUNCTIONS

    public fun is_paused(cb: &CircuitBreaker): bool {
        cb.paused
    }

    public fun campaigns_paused(cb: &CircuitBreaker): bool {
        cb.paused || cb.pause_campaigns
    }

    public fun escrow_paused(cb: &CircuitBreaker): bool {
        cb.paused || cb.pause_escrow
    }

    public fun withdrawals_paused(cb: &CircuitBreaker): bool {
        cb.paused || cb.pause_withdrawals
    }
}
