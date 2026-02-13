module healing_humanity::protocol_fees {

    /// ============================================================
    /// CONSTANTS
    /// ============================================================

    const MAX_BPS: u64 = 10_000;

    // Tier identifiers (internal constants)
    const TIER_NGO: u8 = 1;
    const TIER_CSR: u8 = 2;

    // Fee values in basis points
    const NGO_FEE_BPS: u64 = 125; // 1.25%
    const CSR_FEE_BPS: u64 = 75;  // 0.75%

    // Error codes
    const EInvalidTier: u64 = 1;
    const EInvalidFeeCalculation: u64 = 2;

    /// ============================================================
    /// Public Tier Accessors
    /// ============================================================

    public fun tier_ngo(): u8 { TIER_NGO }
    public fun tier_csr(): u8 { TIER_CSR }

    /// ============================================================
    /// Tier Validation
    /// ============================================================

    public fun is_valid_tier(tier: u8): bool {
        tier == TIER_NGO || tier == TIER_CSR
    }

    /// ============================================================
    /// TIER → FEE MAPPING
    /// ============================================================

    public fun fee_for_tier(tier: u8): u64 {
        if (tier == TIER_CSR) {
            CSR_FEE_BPS
        } else if (tier == TIER_NGO) {
            NGO_FEE_BPS
        } else {
            abort EInvalidTier
        }
    }

    /// ============================================================
    /// FEE CALCULATION
    /// ============================================================

    public fun compute_fee(amount: u64, tier: u8): u64 {
        let fee_bps = fee_for_tier(tier);

        // Defensive invariant
        assert!(fee_bps <= MAX_BPS, EInvalidFeeCalculation);

        amount * fee_bps / MAX_BPS
    }

    public fun compute_net_amount(amount: u64, tier: u8): u64 {
        let fee = compute_fee(amount, tier);
        amount - fee
    }
}
