module healing_humanity::protocol_fees {

    use sui::event;
    use healing_humanity::circuit_breaker;

    /// ============================================================
    /// CONSTANTS
    /// ============================================================

    const MAX_BPS: u64 = 10_000;

    const TIER_NGO: u8 = 1;
    const TIER_CSR: u8 = 2;

    /// Error codes
    const EInvalidTier: u64 = 1;
    const EInvalidFeeCalculation: u64 = 2;
    const EProtocolPaused: u64 = 3;

    /// ============================================================
    /// Shared Fee Configuration
    /// ============================================================

    public struct ProtocolFeeConfig has key {
        id: UID,
        ngo_fee_bps: u64,
        csr_fee_bps: u64,
    }

    public struct FeeAdminCap has key {
        id: UID,
    }

    public struct FeeUpdated has copy, drop {
        tier: u8,
        new_fee_bps: u64,
    }

    /// ============================================================
    /// INIT
    /// ============================================================

    fun init(ctx: &mut TxContext) {

        let config = ProtocolFeeConfig {
            id: object::new(ctx),
            ngo_fee_bps: 125,
            csr_fee_bps: 75,
        };

        let cap = FeeAdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(config);
        transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// ============================================================
    /// Public Tier Accessors
    /// ============================================================

    public fun tier_ngo(): u8 { TIER_NGO }
    public fun tier_csr(): u8 { TIER_CSR }

    public fun is_valid_tier(tier: u8): bool {
        tier == TIER_NGO || tier == TIER_CSR
    }

    /// ============================================================
    /// Fee Update (Circuit Breaker Protected)
    /// ============================================================

    public fun update_fee(
        _cap: &FeeAdminCap,
        cb: &circuit_breaker::CircuitBreaker,
        config: &mut ProtocolFeeConfig,
        tier: u8,
        new_fee_bps: u64
    ) {
        assert!(
            !circuit_breaker::is_paused(cb),
            EProtocolPaused
        );

        assert!(new_fee_bps <= MAX_BPS, EInvalidFeeCalculation);

        if (tier == TIER_NGO) {
            config.ngo_fee_bps = new_fee_bps;
        } else if (tier == TIER_CSR) {
            config.csr_fee_bps = new_fee_bps;
        } else {
            abort EInvalidTier
        };

        event::emit(FeeUpdated {
            tier,
            new_fee_bps,
        });
    }

    /// ============================================================
    /// Fee Queries
    /// ============================================================

    public fun fee_for_tier(
        config: &ProtocolFeeConfig,
        tier: u8
    ): u64 {
        if (tier == TIER_CSR) {
            config.csr_fee_bps
        } else if (tier == TIER_NGO) {
            config.ngo_fee_bps
        } else {
            abort EInvalidTier
        }
    }

    public fun compute_fee(
        config: &ProtocolFeeConfig,
        amount: u64,
        tier: u8
    ): u64 {
        let fee_bps = fee_for_tier(config, tier);
        assert!(fee_bps <= MAX_BPS, EInvalidFeeCalculation);
        amount * fee_bps / MAX_BPS
    }

    public fun compute_net_amount(
        config: &ProtocolFeeConfig,
        amount: u64,
        tier: u8
    ): u64 {
        let fee = compute_fee(config, amount, tier);
        amount - fee
    }
}
