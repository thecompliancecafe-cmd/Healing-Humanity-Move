module healing_humanity::protocol_fees {

    use sui::tx_context::{Self, TxContext};
    use sui::clock::Clock;
    use sui::object::ID;
    use std::option;

    use healing_humanity::circuit_breaker;
    use healing_humanity::events;

    /// ============================================================
    /// CONSTANTS
    /// ============================================================

    const MAX_BPS: u64 = 10_000;
    const MAX_ALLOWED_FEE_BPS: u64 = 1_000; // 10% safety cap

    const TIER_NGO: u8 = 1;
    const TIER_CSR: u8 = 2;

    /// Error codes
    const EInvalidTier: u64 = 1;
    const EInvalidFeeBps: u64 = 2;
    const EProtocolPaused: u64 = 3;

    /// ============================================================
    /// STRUCTS
    /// ============================================================

    public struct ProtocolFeeConfig has key {
        id: UID,
        ngo_fee_bps: u64,
        csr_fee_bps: u64,
    }

    public struct FeeAdminCap has key {
        id: UID,
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
    /// TIER HELPERS
    /// ============================================================

    public fun tier_ngo(): u8 { TIER_NGO }
    public fun tier_csr(): u8 { TIER_CSR }

    public fun is_valid_tier(tier: u8): bool {
        tier == TIER_NGO || tier == TIER_CSR
    }

    fun get_fee_ref_mut(config: &mut ProtocolFeeConfig, tier: u8): &mut u64 {
        if (tier == TIER_NGO) {
            &mut config.ngo_fee_bps
        } else if (tier == TIER_CSR) {
            &mut config.csr_fee_bps
        } else {
            abort EInvalidTier
        }
    }

    fun get_fee_ref(config: &ProtocolFeeConfig, tier: u8): &u64 {
        if (tier == TIER_NGO) {
            &config.ngo_fee_bps
        } else if (tier == TIER_CSR) {
            &config.csr_fee_bps
        } else {
            abort EInvalidTier
        }
    }

    /// ============================================================
    /// FEE UPDATE (Circuit Breaker Protected)
    /// ============================================================

    public fun update_fee(
        _cap: &FeeAdminCap,
        cb: &circuit_breaker::CircuitBreaker,
        config: &mut ProtocolFeeConfig,
        tier: u8,
        new_fee_bps: u64,
        action_id: option::Option<ID>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(!circuit_breaker::is_paused(cb), EProtocolPaused);
        assert!(is_valid_tier(tier), EInvalidTier);
        assert!(new_fee_bps <= MAX_ALLOWED_FEE_BPS, EInvalidFeeBps);

        let fee_ref = get_fee_ref_mut(config, tier);
        let old_fee = *fee_ref;

        *fee_ref = new_fee_bps;

        let admin = tx_context::sender(ctx);

        events::emit_protocol_fee_updated(
            tier,
            old_fee,
            new_fee_bps,
            admin,
            action_id,
            clock
        );
    }

    /// ============================================================
    /// FEE QUERIES
    /// ============================================================

    public fun fee_for_tier(
        config: &ProtocolFeeConfig,
        tier: u8
    ): u64 {
        assert!(is_valid_tier(tier), EInvalidTier);
        *get_fee_ref(config, tier)
    }

    public fun compute_fee(
        config: &ProtocolFeeConfig,
        amount: u64,
        tier: u8
    ): u64 {
        let fee_bps = fee_for_tier(config, tier);

        // Prevent overflow using u128
        ((amount as u128) * (fee_bps as u128) / (MAX_BPS as u128)) as u64
    }

    public fun compute_net_amount(
        config: &ProtocolFeeConfig,
        amount: u64,
        tier: u8
    ): u64 {
        let fee = compute_fee(config, amount, tier);
        assert!(amount >= fee, EInvalidFeeBps);
        amount - fee
    }

    /// Optional helper for frontends
    public fun get_all_fees(config: &ProtocolFeeConfig): (u64, u64) {
        (config.ngo_fee_bps, config.csr_fee_bps)
    }
}
