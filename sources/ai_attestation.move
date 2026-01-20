module healing_humanity::ai_attestation {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::string::String;
    use sui::clock::Clock;
    use healing_humanity::ai_oracle;

    struct Attestation has key, store {
        id: UID,
        campaign_id: ID,
        audit_hash: String,
        ai_model: String,
        confidence: u64,
        timestamp: u64,
    }

    public fun submit_attestation(
        registry: &ai_oracle::OracleRegistry,
        oracle: &signer,
        campaign_id: ID,
        audit_hash: String,
        ai_model: String,
        confidence: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): Attestation {
        assert!(ai_oracle::is_oracle(registry, signer::address_of(oracle)), 1);

        Attestation {
            id: object::new(ctx),
            campaign_id,
            audit_hash,
            ai_model,
            confidence,
            timestamp: clock::now_ms(clock),
        }
    }
}
