module healing_humanity::circuit_breaker {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;

    /// Shared circuit breaker object
    public struct CircuitBreaker has key {
        id: UID,
        paused: bool,
    }

    /// Admin capability for pause control
    public struct CircuitAdminCap has key {
        id: UID,
    }

    /// Event: protocol paused
    public struct ProtocolPaused has copy, drop {}

    /// Event: protocol unpaused
    public struct ProtocolUnpaused has copy, drop {}

    /// Initialize circuit breaker (callable once)
    public fun init(ctx: &mut TxContext): (CircuitBreaker, CircuitAdminCap) {
        let breaker = CircuitBreaker {
            id: UID::new(ctx),
            paused: false,
        };

        let admin_cap = CircuitAdminCap {
            id: UID::new(ctx),
        };

        // Share the breaker so all modules can read it
        transfer::share_object(breaker);

        // Return admin capability to caller
        (breaker, admin_cap)
    }

    /// Pause protocol operations (admin only)
    public fun pause(
        _admin: &CircuitAdminCap,
        cb: &mut CircuitBreaker
    ) {
        if (!cb.paused) {
            cb.paused = true;
            event::emit(ProtocolPaused {});
        }
    }

    /// Resume protocol operations (admin only)
    public fun unpause(
        _admin: &CircuitAdminCap,
        cb: &mut CircuitBreaker
    ) {
        if (cb.paused) {
            cb.paused = false;
            event::emit(ProtocolUnpaused {});
        }
    }

    /// Read-only check used by other modules
    public fun is_paused(cb: &CircuitBreaker): bool {
        cb.paused
    }
}
