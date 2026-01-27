module healing_humanity::protocol_fees {
    use sui::object::{UID, object};
    use sui::tx_context::TxContext;

    struct FeeConfig has key {
        id: UID,
        treasury: address,
        fee_bps: u64,
    }

    public fun init(
        treasury: address,
        fee_bps: u64,
        ctx: &mut TxContext
    ): FeeConfig {
        FeeConfig {
            id: object::new(ctx),
            treasury,
            fee_bps,
        }
    }
}
