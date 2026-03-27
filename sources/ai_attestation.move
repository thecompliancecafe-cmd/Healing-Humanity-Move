module healing_humanity::ai_attestation {

    use std::string;
    use sui::event;

    use healing_humanity::identity::{Self, Identity};

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_IDENTITY_INACTIVE: u64 = 1;
    const E_INVALID_ROLE: u64 = 2;
    const E_IDENTITY_NOT_VERIFIED: u64 = 3;

    /// -----------------------------
    /// AI Attestation Object
    /// -----------------------------
    public struct Attestation has key {
        id: object::UID,
        campaign_id: object::ID,
        milestone: u64,
        hash: string::String,
        oracle_identity: object::ID,
        oracle_wallet: address,
    }

    /// -----------------------------
    /// Event
    /// -----------------------------
    public struct AttestationSubmitted has copy, drop {
        campaign_id: object::ID,
        milestone: u64,
        oracle_identity: object::ID,
        oracle_wallet: address,
    }

    /// -----------------------------
    /// INTERNAL: Submit Attestation
    /// -----------------------------
    public(package) fun submit_internal(
        oracle_identity: &Identity,
        campaign_id: object::ID,
        milestone: u64,
        hash: string::String,
        ctx: &mut tx_context::TxContext
    ): Attestation {

        let sender = tx_context::sender(ctx);

        assert!(identity::is_active(oracle_identity), E_IDENTITY_INACTIVE);
        assert!(identity::is_verified(oracle_identity), E_IDENTITY_NOT_VERIFIED);

        assert!(
            identity::is_ai(oracle_identity) ||
            identity::get_role(oracle_identity) == 5,
            E_INVALID_ROLE
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
    public fun oracle_identity_of(att: &Attestation): object::ID {
        att.oracle_identity
    }

    public fun oracle_wallet_of(att: &Attestation): address {
        att.oracle_wallet
    }

    public fun milestone_of(att: &Attestation): u64 {
        att.milestone
    }

    public fun campaign_of(att: &Attestation): object::ID {
        att.campaign_id
    }
}
