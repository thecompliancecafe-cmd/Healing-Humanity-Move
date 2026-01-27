module healing_humanity::ai_attestation {
    use sui::object::{UID, ID, object};
    use sui::tx_context::TxContext;
    use std::string;

    struct Attestation has key {
        id: UID,
        campaign_id: ID,
        milestone: u64,
        hash: string::String,
    }

    public fun submit(
        campaign_id: ID,
        milestone: u64,
        hash: string::String,
        ctx: &mut TxContext
    ): Attestation {
        Attestation {
            id: object::new(ctx),
            campaign_id,
            milestone,
            hash,
        }
    }
}
