module healing_humanity::circuit_breaker {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;

    struct CircuitBreaker has key {
        id: UID,
        paused: bool,
        admin: address,
    }

    public fun init_circuit(admin: address, ctx: &mut TxContext): CircuitBreaker {
        CircuitBreaker { id: object::new(ctx), paused: false, admin }
    }

    public fun pause(cb: &mut CircuitBreaker) {
        cb.paused = true;
    }

    public fun unpause(cb: &mut CircuitBreaker) {
        cb.paused = false;
    }
}
