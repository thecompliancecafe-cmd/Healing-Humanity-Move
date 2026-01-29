module healing_humanity::circuit_breaker {
    use sui::object::UID;
    use sui::tx_context::{Self, TxContext};
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

    /// One-time package initialization
    fun init(ctx: &mut TxContext) {
        let breaker = CircuitBreaker {
            id: UID::new(ctx),
            paused: false,
        };

        let admin_cap = CircuitAdminCap {
            id: UID::new(ctx),
        };

        // Share the breaker so all modules can read it
        transfer::share_object(breaker);

        // Give pause/unpause authority to deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));
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
