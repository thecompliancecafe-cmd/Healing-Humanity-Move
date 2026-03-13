module healing_humanity::ai_attestation {

    use std::string::String;
    use sui::event;

    use healing_humanity::ai_oracle::{Self, OracleRegistry};
    use healing_humanity::identity::{Self, Identity};

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_NOT_ORACLE: u64 = 0;
    const E_IDENTITY_INACTIVE: u64 = 1;
    const E_INVALID_ROLE: u64 = 2;
    const E_IDENTITY_NOT_VERIFIED: u64 = 3;

    /// -----------------------------
    /// AI Attestation Object
    /// -----------------------------
    public struct Attestation has key {
        id: UID,
        campaign_id: ID,
        milestone: u64,
        hash: String,
        oracle_identity: ID,
        oracle_wallet: address,
    }

    /// -----------------------------
    /// Event: Attestation Submitted
    /// -----------------------------
    public struct AttestationSubmitted has copy, drop {
        campaign_id: ID,
        milestone: u64,
        oracle_identity: ID,
        oracle_wallet: address,
    }

    /// -----------------------------
    /// Submit AI Attestation
    /// -----------------------------
    public fun submit(
        registry: &OracleRegistry,
        oracle_identity: &Identity,
        campaign_id: ID,
        milestone: u64,
        hash: String,
        ctx: &mut TxContext
    ): Attestation {

        let sender = tx_context::sender(ctx);

        // Identity must be active
        assert!(
            identity::is_active(oracle_identity),
            E_IDENTITY_INACTIVE
        );

        // Identity must be verified
        assert!(
            identity::is_verified(oracle_identity),
            E_IDENTITY_NOT_VERIFIED
        );

        // Only AI agent or Oracle role allowed
        assert!(
            identity::is_ai(oracle_identity) ||
            identity::get_role(oracle_identity) == 5,
            E_INVALID_ROLE
        );

        // Oracle registry validation
        assert!(
            ai_oracle::is_oracle(registry, oracle_identity, sender),
            E_NOT_ORACLE
        );

        let attestation = Attestation {
            id: object::new(ctx),
            campaign_id,
            milestone,
            hash,
            oracle_identity: object::id(oracle_identity),
            oracle_wallet: sender,
        };

        event::emit(AttestationSubmitted {
            campaign_id,
            milestone,
            oracle_identity: object::id(oracle_identity),
            oracle_wallet: sender,
        });

        attestation
    }

    /// -----------------------------
    /// Read Helpers
    /// -----------------------------

    public fun oracle_identity_of(att: &Attestation): ID {
        att.oracle_identity
    }

    public fun oracle_wallet_of(att: &Attestation): address {
        att.oracle_wallet
    }

    public fun milestone_of(att: &Attestation): u64 {
        att.milestone
    }

    public fun campaign_of(att: &Attestation): ID {
        att.campaign_id
    }
}
