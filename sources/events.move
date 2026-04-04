module healing_humanity::events {

    use sui::event;
    use sui::clock::Clock;
    use sui::object::ID;

    /// =========================
    /// CAMPAIGN EVENTS
    /// =========================

    public struct CampaignCreated has copy, drop {
        campaign_id: ID,
        creator: address,
        metadata_hash: vector<u8>,
        funding_goal: u64,
        timestamp_ms: u64,
    }

    public struct CampaignStatusChanged has copy, drop {
        campaign_id: ID,
        old_status: u8,
        new_status: u8,
        actor: address,
        reason: vector<u8>,
        timestamp_ms: u64,
    }

    /// ✅ NEW: Campaign ↔ Escrow link event
    public struct CampaignEscrowLinked has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        timestamp_ms: u64,
    }

    /// ✅ NEW: Campaign funded event (aggregate-level)
    public struct CampaignFunded has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        amount: u64,
        total_raised: u64,
        timestamp_ms: u64,
    }

    /// =========================
    /// ESCROW EVENTS
    /// =========================

    public struct EscrowCreated has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        amount: u64,
        timestamp_ms: u64,
    }

    public struct EscrowClosed has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        timestamp_ms: u64,
    }

    public struct EscrowFunded has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        funder: address,
        amount: u64,
        timestamp_ms: u64,
    }

    public struct MilestoneCreated has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        percentage: u64,
        timestamp_ms: u64,
    }

    public struct MilestoneApproved has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        approver: address,
        timestamp_ms: u64,
    }

    public struct EscrowReleased has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        recipient: address,
        amount: u64,
        fee_taken: u64,
        timestamp_ms: u64,
    }

    /// =========================
    /// 🔥 NEW ORACLE EVENTS
    /// =========================

    public struct OracleRegistered has copy, drop {
        oracle_id: ID,
        owner: address,
        endpoint: vector<u8>,
        model: vector<u8>,
        timestamp_ms: u64,
    }

    public struct OracleRateLimited has copy, drop {
        oracle_id: ID,
        last_submission: u64,
        attempted_at: u64,
        timestamp_ms: u64,
    }

    public struct OracleRoundStarted has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        round: u64,
        quorum: u64,
        oracle_count: u64,
        started_by: address,
        timestamp_ms: u64,
    }

    public struct MilestoneReadyForRelease has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        timestamp_ms: u64,
    }

    /// =========================
    /// EXISTING ORACLE EVENTS
    /// =========================

    public struct OracleVoteSubmitted has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        oracle: address,
        vote: bool,
        round: u64,
        timestamp_ms: u64,
    }

    public struct OracleRoundFinalized has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        round: u64,
        result: bool,
        total_votes: u64,
        approvals: u64,
        timestamp_ms: u64,
    }

    /// =========================
    /// FEES + TREASURY
    /// =========================

    public struct FeeCollected has copy, drop {
        campaign_id: ID,
        escrow_id: ID,
        amount: u64,
        fee_bps: u64,
        payer: address,
        timestamp_ms: u64,
    }

    public struct TreasuryDeposit has copy, drop {
        source: vector<u8>,
        amount: u64,
        timestamp_ms: u64,
    }

    /// =========================
    /// REPUTATION + IDENTITY
    /// =========================

    public struct ReputationUpdated has copy, drop {
        user: address,
        delta: u64,
        is_positive: bool,
        reason: vector<u8>,
        campaign_id: ID,
        timestamp_ms: u64,
    }

    public struct IdentityVerified has copy, drop {
        user: address,
        verifier: address,
        level: u8,
        timestamp_ms: u64,
    }

    /// =========================
    /// CIRCUIT BREAKER
    /// =========================

    public struct ProtocolPaused has copy, drop {
        admin: address,
        reason: vector<u8>,
        timestamp_ms: u64,
    }

    public struct ProtocolUnpaused has copy, drop {
        admin: address,
        timestamp_ms: u64,
    }

    /// =========================
    /// INTERNAL HELPER
    /// =========================

    fun now(clock: &Clock): u64 {
        clock.timestamp_ms()
    }

    /// =========================
    /// EMIT FUNCTIONS
    /// =========================

    public fun emit_campaign_created(
        campaign_id: ID,
        creator: address,
        metadata_hash: vector<u8>,
        funding_goal: u64,
        clock: &Clock
    ) {
        event::emit(CampaignCreated {
            campaign_id,
            creator,
            metadata_hash,
            funding_goal,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_campaign_status_changed(
        campaign_id: ID,
        old_status: u8,
        new_status: u8,
        actor: address,
        reason: vector<u8>,
        clock: &Clock
    ) {
        event::emit(CampaignStatusChanged {
            campaign_id,
            old_status,
            new_status,
            actor,
            reason,
            timestamp_ms: now(clock),
        });
    }

    /// ✅ FIXED FUNCTION
    public fun emit_campaign_escrow_linked(
        campaign_id: ID,
        escrow_id: ID,
        clock: &Clock
    ) {
        event::emit(CampaignEscrowLinked {
            campaign_id,
            escrow_id,
            timestamp_ms: now(clock),
        });
    }

    /// ✅ FIXED FUNCTION
    public fun emit_campaign_funded(
        campaign_id: ID,
        escrow_id: ID,
        amount: u64,
        total_raised: u64,
        clock: &Clock
    ) {
        event::emit(CampaignFunded {
            campaign_id,
            escrow_id,
            amount,
            total_raised,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_escrow_created(
        campaign_id: ID,
        escrow_id: ID,
        amount: u64,
        clock: &Clock
    ) {
        event::emit(EscrowCreated {
            campaign_id,
            escrow_id,
            amount,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_escrow_closed(
        campaign_id: ID,
        escrow_id: ID,
        clock: &Clock
    ) {
        event::emit(EscrowClosed {
            campaign_id,
            escrow_id,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_escrow_funded(
        campaign_id: ID,
        escrow_id: ID,
        funder: address,
        amount: u64,
        clock: &Clock
    ) {
        event::emit(EscrowFunded {
            campaign_id,
            escrow_id,
            funder,
            amount,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_milestone_created(
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        percentage: u64,
        clock: &Clock
    ) {
        event::emit(MilestoneCreated {
            campaign_id,
            escrow_id,
            milestone_id,
            percentage,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_milestone_approved(
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        approver: address,
        clock: &Clock
    ) {
        event::emit(MilestoneApproved {
            campaign_id,
            escrow_id,
            milestone_id,
            approver,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_escrow_released(
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        recipient: address,
        amount: u64,
        fee_taken: u64,
        clock: &Clock
    ) {
        event::emit(EscrowReleased {
            campaign_id,
            escrow_id,
            milestone_id,
            recipient,
            amount,
            fee_taken,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_oracle_vote(
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        oracle: address,
        vote: bool,
        round: u64,
        clock: &Clock
    ) {
        event::emit(OracleVoteSubmitted {
            campaign_id,
            escrow_id,
            milestone_id,
            oracle,
            vote,
            round,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_oracle_result(
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        round: u64,
        result: bool,
        total_votes: u64,
        approvals: u64,
        clock: &Clock
    ) {
        event::emit(OracleRoundFinalized {
            campaign_id,
            escrow_id,
            milestone_id,
            round,
            result,
            total_votes,
            approvals,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_oracle_registered(
        oracle_id: ID,
        owner: address,
        endpoint: vector<u8>,
        model: vector<u8>,
        clock: &Clock
    ) {
        event::emit(OracleRegistered {
            oracle_id,
            owner,
            endpoint,
            model,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_oracle_rate_limited(
        oracle_id: ID,
        last_submission: u64,
        attempted_at: u64,
        clock: &Clock
    ) {
        event::emit(OracleRateLimited {
            oracle_id,
            last_submission,
            attempted_at,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_oracle_round_started(
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        round: u64,
        quorum: u64,
        oracle_count: u64,
        started_by: address,
        clock: &Clock
    ) {
        event::emit(OracleRoundStarted {
            campaign_id,
            escrow_id,
            milestone_id,
            round,
            quorum,
            oracle_count,
            started_by,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_milestone_ready_for_release(
        campaign_id: ID,
        escrow_id: ID,
        milestone_id: u64,
        clock: &Clock
    ) {
        event::emit(MilestoneReadyForRelease {
            campaign_id,
            escrow_id,
            milestone_id,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_fee_collected(
        campaign_id: ID,
        escrow_id: ID,
        amount: u64,
        fee_bps: u64,
        payer: address,
        clock: &Clock
    ) {
        event::emit(FeeCollected {
            campaign_id,
            escrow_id,
            amount,
            fee_bps,
            payer,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_treasury_deposit(
        source: vector<u8>,
        amount: u64,
        clock: &Clock
    ) {
        event::emit(TreasuryDeposit {
            source,
            amount,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_reputation_updated(
        user: address,
        delta: u64,
        is_positive: bool,
        reason: vector<u8>,
        campaign_id: ID,
        clock: &Clock
    ) {
        event::emit(ReputationUpdated {
            user,
            delta,
            is_positive,
            reason,
            campaign_id,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_identity_verified(
        user: address,
        verifier: address,
        level: u8,
        clock: &Clock
    ) {
        event::emit(IdentityVerified {
            user,
            verifier,
            level,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_protocol_paused(
        admin: address,
        reason: vector<u8>,
        clock: &Clock
    ) {
        event::emit(ProtocolPaused {
            admin,
            reason,
            timestamp_ms: now(clock),
        });
    }

    public fun emit_protocol_unpaused(
        admin: address,
        clock: &Clock
    ) {
        event::emit(ProtocolUnpaused {
            admin,
            timestamp_ms: now(clock),
        });
    }
}
