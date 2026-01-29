module healing_humanity::ai_attestation {
    use sui::object::{UID, ID};
    use sui::tx_context::{Self, TxContext};
    use std::string;
    use sui::event;

    /// AI attestation object for a campaign milestone
    public struct Attestation has key {
        id: UID,
        campaign_id: ID,
        milestone: u64,
        hash: string::String,
        submitter: address,
    }

    /// Event: attestation submitted
    public struct AttestationSubmitted has copy, drop {
        campaign_id: ID,
        milestone: u64,
        submitter: address,
    }

    /// Submit an AI attestation (permissionless)
    public fun submit(
        campaign_id: ID,
        milestone: u64,
        hash: string::String,
        ctx: &mut TxContext
    ): Attestation {
        let sender = tx_context::sender(ctx);

        let attestation = Attestation {
            id: UID::new(ctx),
            campaign_id,
            milestone,
            hash,
            submitter: sender,
        };

        event::emit(AttestationSubmitted {
            campaign_id,
            milestone,
            submitter: sender,
        });

        attestation
    }
}
