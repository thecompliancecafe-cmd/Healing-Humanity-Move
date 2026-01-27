module healing_humanity::circuit_breaker {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;

    struct CircuitBreaker has key {
        id: UID,
        paused: bool,
    }

    struct CircuitAdminCap has key {
        id: UID,
    }

    public fun init(ctx: &mut TxContext): (CircuitBreaker, CircuitAdminCap) {
        (
            CircuitBreaker {
                id: object::new(ctx),
                paused: false,
            },
            CircuitAdminCap { id: object::new(ctx) }
        )
    }

    public fun pause(_: &CircuitAdminCap, cb: &mut CircuitBreaker) {
        cb.paused = true;
    }

    public fun unpause(_: &CircuitAdminCap, cb: &mut CircuitBreaker) {
        cb.paused = false;
    }
}
