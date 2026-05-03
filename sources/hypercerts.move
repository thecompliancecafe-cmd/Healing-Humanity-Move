module healing_humanity::hypercerts {

    use std::string::String;
    use std::vector;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::event;

    /// =========================
    /// ERRORS
    /// =========================

    const E_INVALID_INPUT: u64 = 0;
    const E_REVOKED: u64 = 1;
    const E_ALREADY_VERIFIED: u64 = 2;
    const E_NOT_VERIFIED: u64 = 3;
    const E_INSUFFICIENT_UNITS: u64 = 4;
    const E_SOULBOUND: u64 = 5;

    /// =========================
    /// ENUMS
    /// =========================

    public enum VerificationStatus has copy, drop, store {
        Pending,
        Verified,
        Rejected
    }

    public enum Transferability has copy, drop, store {
        Soulbound,
        Transferable
    }

    /// =========================
    /// CORE HYPERCERT
    /// =========================

    public struct Hypercert has key {
        id: UID,

        campaign_id: ID,
        creator: address,

        impact_scope: String,
        impact_units: u64,

        total_units: u64,
        remaining_units: u64,

        metadata_hash: String,

        verification_status: VerificationStatus,
        oracle_approvals: vector<address>,

        created_at: u64,
        valid_until: u64,
        revoked: bool,

        transferability: Transferability
    }

    /// =========================
    /// FRACTIONS
    /// =========================

    public struct HypercertFraction has key {
        id: UID,
        parent_id: ID,
        owner: address,
        units: u64
    }

    /// =========================
    /// EVENTS
    /// =========================

    public struct HypercertMinted has copy, drop {
        hypercert_id: ID,
        campaign_id: ID,
        total_units: u64
    }

    public struct HypercertVerified has copy, drop {
        hypercert_id: ID,
        oracle_count: u64
    }

    public struct FractionMinted has copy, drop {
        hypercert_id: ID,
        owner: address,
        units: u64
    }

    public struct HypercertRevoked has copy, drop {
        hypercert_id: ID
    }

    /// =========================
    /// CREATE
    /// =========================

    public fun create_claim(
        campaign_id: ID,
        creator: address,
        impact_scope: String,
        impact_units: u64,
        metadata_hash: String,
        total_units: u64,
        valid_until: u64,
        transferability: Transferability,
        ctx: &mut TxContext
    ): Hypercert {

        assert!(impact_units > 0, E_INVALID_INPUT);
        assert!(total_units > 0, E_INVALID_INPUT);

        let cert = Hypercert {
            id: object::new(ctx),
            campaign_id,
            creator,
            impact_scope,
            impact_units,
            total_units,
            remaining_units: total_units,
            metadata_hash,
            verification_status: VerificationStatus::Pending,
            oracle_approvals: vector::empty(),
            created_at: tx_context::epoch(ctx),
            valid_until,
            revoked: false,
            transferability
        };

        event::emit(HypercertMinted {
            hypercert_id: object::id(&cert),
            campaign_id,
            total_units
        });

        cert
    }

    /// =========================
    /// ORACLE INJECTION
    /// =========================

    public fun add_oracle_approvals(
        cert: &mut Hypercert,
        oracles: vector<address>
    ) {
        assert!(!cert.revoked, E_REVOKED);

        let mut i = 0;
        let len = vector::length(&oracles);

        while (i < len) {
            vector::push_back(
                &mut cert.oracle_approvals,
                *vector::borrow(&oracles, i)
            );
            i = i + 1;
        };
    }

    /// =========================
    /// FINALIZE
    /// =========================

    public fun finalize_verification(
        cert: &mut Hypercert,
        approved: bool
    ) {
        assert!(!cert.revoked, E_REVOKED);
        assert!(cert.verification_status == VerificationStatus::Pending, E_ALREADY_VERIFIED);

        if (approved) {
            cert.verification_status = VerificationStatus::Verified;

            event::emit(HypercertVerified {
                hypercert_id: object::id(cert),
                oracle_count: vector::length(&cert.oracle_approvals)
            });
        } else {
            cert.verification_status = VerificationStatus::Rejected;
        }
    }

    public fun verify_with_oracles(
        cert: &mut Hypercert,
        oracles: vector<address>
    ) {
        add_oracle_approvals(cert, oracles);
        finalize_verification(cert, true);
    }

    /// =========================
    /// FRACTION MINT
    /// =========================

    public fun mint_fraction(
        cert: &mut Hypercert,
        to: address,
        units: u64,
        ctx: &mut TxContext
    ): HypercertFraction {

        assert!(cert.verification_status == VerificationStatus::Verified, E_NOT_VERIFIED);
        assert!(!cert.revoked, E_REVOKED);
        assert!(units > 0, E_INVALID_INPUT);
        assert!(cert.remaining_units >= units, E_INSUFFICIENT_UNITS);

        cert.remaining_units = cert.remaining_units - units;

        let fraction = HypercertFraction {
            id: object::new(ctx),
            parent_id: object::id(cert),
            owner: to,
            units
        };

        event::emit(FractionMinted {
            hypercert_id: object::id(cert),
            owner: to,
            units
        });

        fraction
    }

    /// =========================
    /// TRANSFER
    /// =========================

    public fun transfer_fraction(
        fraction: &mut HypercertFraction,
        new_owner: address,
        cert: &Hypercert
    ) {
        assert!(cert.transferability == Transferability::Transferable, E_SOULBOUND);
        fraction.owner = new_owner;
    }

    /// =========================
    /// REVOCATION
    /// =========================

    public fun revoke(cert: &mut Hypercert) {
        assert!(!cert.revoked, E_REVOKED);

        cert.revoked = true;

        event::emit(HypercertRevoked {
            hypercert_id: object::id(cert)
        });
    }

    /// =========================
    /// PUBLIC GETTERS (USED BY OTHER MODULES)
    /// =========================

    public fun is_verified(cert: &Hypercert): bool {
        cert.verification_status == VerificationStatus::Verified
    }

    public fun get_impact_units(cert: &Hypercert): u64 {
        cert.impact_units
    }

    public fun get_creator(cert: &Hypercert): address {
        cert.creator
    }

    public fun get_campaign(cert: &Hypercert): ID {
        cert.campaign_id
    }

    public fun remaining_units(cert: &Hypercert): u64 {
        cert.remaining_units
    }
}
