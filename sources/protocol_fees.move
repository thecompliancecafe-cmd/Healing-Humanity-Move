module healing_humanity::protocol_fees {

    /// Protocol fee configuration
    /// fee_bps = fee in basis points (1% = 100 bps)
    public struct FeeConfig has key {
        id: object::UID,
        treasury: address,
        fee_bps: u64,
    }

    /// Create protocol fee configuration
    public fun create(
        treasury: address,
        fee_bps: u64,
        ctx: &mut tx_context::TxContext
    ): FeeConfig {
        FeeConfig {
            id: object::new(ctx),
            treasury,
            fee_bps,
        }
    }

    /// Read fee in basis points
    public fun fee_bps(cfg: &FeeConfig): u64 {
        cfg.fee_bps
    }

    /// Read treasury address
    public fun treasury(cfg: &FeeConfig): address {
        cfg.treasury
    }
}
