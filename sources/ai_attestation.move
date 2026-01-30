module healing_humanity::ai_attestation {
    use std::string;
    use sui::event;

    use healing_humanity::ai_oracle::{Self, OracleRegistry};

    /// AI attestation object for a campaign milestone
    public struct Attestation has key {
        id: object::UID,
        campaign_id: object::ID,
        milestone: u64,
        hash: string::String,
        oracle: address,
    }

    /// Event: attestation submitted
    public struct AttestationSubmitted has copy, drop {
        campaign_id: object::ID,
        milestone: u64,
        oracle: address,
    }

    /// Submit an AI attestation (oracle only)
    public fun submit(
        registry: &OracleRegistry,
        campaign_id: object::ID,
        milestone: u64,
        hash: string::String,
        ctx: &mut tx_context::TxContext
    ): Attestation {
        let sender = tx_context::sender(ctx);

        // Enforce oracle authorization
        assert!(
            ai_oracle::is_oracle(registry, sender),
            0
        );

        let attestation = Attestation {
            id: object::new(ctx),
            campaign_id,
            milestone,
            hash,
            oracle: sender,
        };

        event::emit(AttestationSubmitted {
            campaign_id,
            milestone,
            oracle: sender,
        });

        attestation
    }
}
