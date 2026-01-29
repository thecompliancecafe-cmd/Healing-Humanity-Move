module healing_humanity::ai_attestation {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use std::string;

    /// AI attestation object for a campaign milestone
    public struct Attestation has key {
        id: UID,
        campaign_id: UID,
        milestone: u64,
        hash: string::String,
    }

    /// Create a new attestation object
    ///
    /// Anyone can submit, but in practice this should be
    /// guarded by ai_oracle checks at a higher layer.
    public fun submit(
        campaign_id: UID,
        milestone: u64,
        hash: string::String,
        ctx: &mut TxContext
    ): Attestation {
        Attestation {
            id: sui::object::new(ctx),
            campaign_id,
            milestone,
            hash,
        }
    }
}
