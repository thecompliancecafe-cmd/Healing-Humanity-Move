module healing_humanity::ai_oracle {

    use sui::clock;
    use sui::table;
    use sui::bcs;

    use healing_humanity::identity;
    use healing_humanity::circuit_breaker;
    use healing_humanity::events;

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_ALREADY_ORACLE: u64 = 0;
    const E_PAUSED: u64 = 2;
    const E_RATE_LIMIT: u64 = 3;
    const E_NOT_ORACLE: u64 = 4;
    const E_ALREADY_VOTED: u64 = 5;
    const E_ROUND_NOT_FOUND: u64 = 6;
    const E_ROUND_FINALIZED: u64 = 7;
    const E_ROUND_ALREADY_EXISTS: u64 = 8;
    const E_QUORUM_NOT_REACHED: u64 = 9;
    const E_ROUND_EXPIRED: u64 = 10;

    /// -----------------------------
    /// Oracle Data
    /// -----------------------------
    public struct OracleInfo has drop, store {
        owner: address,
        added_at: u64,
        reputation: u64,
        last_submission: u64,
        endpoint: vector<u8>,
        pubkey: vector<u8>,
        model: vector<u8>,
    }

    /// -----------------------------
    /// Voting Round
    /// -----------------------------
    public struct VotingRound has store {
        campaign_id: object::ID,
        escrow_id: object::ID,
        milestone_id: u64,
        round: u64,
        approvals: u64,
        rejections: u64,
        total_votes: u64,
        finalized: bool,
        voters: table::Table<object::ID, bool>,
        quorum: u64,
        created_at: u64,
        expiry_ms: u64,
        finalized_by: address
    }

    public struct OracleRegistry has key {
        id: object::UID,
        oracles: table::Table<object::ID, OracleInfo>,
        rounds: table::Table<vector<u8>, VotingRound>,
        oracle_count: u64,
    }

    public struct OracleAdminCap has key {
        id: object::UID,
    }

    fun init(ctx: &mut tx_context::TxContext) {
        let registry = OracleRegistry {
            id: object::new(ctx),
            oracles: table::new(ctx),
            rounds: table::new(ctx),
            oracle_count: 0,
        };
        transfer::share_object(registry);
    }

    public fun create_admin_cap(ctx: &mut tx_context::TxContext) {
        let cap = OracleAdminCap { id: object::new(ctx) };
        transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// -----------------------------
    /// Add Oracle
    /// -----------------------------
    public fun add_oracle(
        _cap: &OracleAdminCap,
        registry: &mut OracleRegistry,
        oracle_identity: &identity::Identity,
        endpoint: vector<u8>,
        pubkey: vector<u8>,
        model: vector<u8>,
        clock_ref: &clock::Clock
    ) {
        let id = object::id(oracle_identity);
        assert!(!table::contains(&registry.oracles, id), E_ALREADY_ORACLE);

        let now = clock::timestamp_ms(clock_ref);
        let owner = identity::get_owner(oracle_identity);

        let info = OracleInfo {
            owner,
            added_at: now,
            reputation: 1,
            last_submission: 0,
            endpoint,
            pubkey,
            model,
        };

        table::add(&mut registry.oracles, id, info);
        registry.oracle_count = registry.oracle_count + 1;

        events::emit_oracle_registered(
            id,
            owner,
            endpoint,
            model,
            clock_ref
        );
    }

    /// -----------------------------
    /// Rate Limit
    /// -----------------------------
    fun assert_rate_limit(
        registry: &OracleRegistry,
        id: object::ID,
        clock_ref: &clock::Clock
    ) {
        let info = table::borrow(&registry.oracles, id);
        let now = clock::timestamp_ms(clock_ref);
        let min_interval = 5000;

        if (now < info.last_submission + min_interval) {
            events::emit_oracle_rate_limited(id, info.last_submission, now, clock_ref);
        };

        assert!(now >= info.last_submission + min_interval, E_RATE_LIMIT);
    }

    fun update_submission_time(
        registry: &mut OracleRegistry,
        id: object::ID,
        clock_ref: &clock::Clock
    ) {
        let info = table::borrow_mut(&mut registry.oracles, id);
        info.last_submission = clock::timestamp_ms(clock_ref);
        info.reputation = info.reputation + 1;

        events::emit_reputation_updated(
            info.owner,
            1,
            true,
            b"oracle_vote",
            id,
            clock_ref
        );
    }

    /// -----------------------------
    /// Round Key
    /// -----------------------------
    fun round_key(
        campaign_id: object::ID,
        escrow_id: object::ID,
        milestone_id: u64,
        round: u64
    ): vector<u8> {
        let mut key = vector::empty<u8>();
        vector::append(&mut key, object::id_to_bytes(&campaign_id));
        vector::append(&mut key, object::id_to_bytes(&escrow_id));
        vector::append(&mut key, bcs::to_bytes(&milestone_id));
        vector::append(&mut key, bcs::to_bytes(&round));
        key
    }

    /// -----------------------------
    /// Start Round
    /// -----------------------------
    public fun start_round(
        _cap: &OracleAdminCap,
        registry: &mut OracleRegistry,
        campaign_id: object::ID,
        escrow_id: object::ID,
        milestone_id: u64,
        round: u64,
        quorum: u64,
        expiry_ms: u64,
        cb: &circuit_breaker::CircuitBreaker,
        clock_ref: &clock::Clock,
        ctx: &mut tx_context::TxContext
    ) {
        assert!(!circuit_breaker::is_paused(cb), E_PAUSED);

        let key = round_key(campaign_id, escrow_id, milestone_id, round);
        assert!(!table::contains(&registry.rounds, key), E_ROUND_ALREADY_EXISTS);

        let now = clock::timestamp_ms(clock_ref);

        let vr = VotingRound {
            campaign_id,
            escrow_id,
            milestone_id,
            round,
            approvals: 0,
            rejections: 0,
            total_votes: 0,
            finalized: false,
            voters: table::new(ctx),
            quorum,
            created_at: now,
            expiry_ms,
            finalized_by: @0x0
        };

        table::add(&mut registry.rounds, key, vr);

        events::emit_oracle_round_started(
            campaign_id,
            escrow_id,
            milestone_id,
            round,
            quorum,
            registry.oracle_count,
            tx_context::sender(ctx),
            clock_ref
        );
    }

    /// -----------------------------
    /// Submit Vote
    /// -----------------------------
    public fun submit_vote(
        registry: &mut OracleRegistry,
        oracle_identity: &identity::Identity,
        campaign_id: object::ID,
        escrow_id: object::ID,
        milestone_id: u64,
        round: u64,
        vote: bool,
        cb: &circuit_breaker::CircuitBreaker,
        clock_ref: &clock::Clock,
        ctx: &tx_context::TxContext
    ) {
        assert!(!circuit_breaker::is_paused(cb), E_PAUSED);

        let sender = tx_context::sender(ctx);
        assert!(is_oracle(registry, oracle_identity, sender), E_NOT_ORACLE);

        let id = object::id(oracle_identity);

        assert_rate_limit(registry, id, clock_ref);
        update_submission_time(registry, id, clock_ref);

        let key = round_key(campaign_id, escrow_id, milestone_id, round);
        assert!(table::contains(&registry.rounds, key), E_ROUND_NOT_FOUND);

        let vr = table::borrow_mut(&mut registry.rounds, key);
        assert!(!vr.finalized, E_ROUND_FINALIZED);

        let now = clock::timestamp_ms(clock_ref);
        assert!(now <= vr.created_at + vr.expiry_ms, E_ROUND_EXPIRED);

        assert!(!table::contains(&vr.voters, id), E_ALREADY_VOTED);

        let info = table::borrow(&registry.oracles, id);
        let weight = if (info.reputation == 0) { 1 } else { info.reputation };

        table::add(&mut vr.voters, id, vote);

        vr.total_votes = vr.total_votes + weight;

        if (vote) {
            vr.approvals = vr.approvals + weight;
        } else {
            vr.rejections = vr.rejections + weight;
        };

        events::emit_oracle_vote(
            campaign_id,
            escrow_id,
            milestone_id,
            sender,
            vote,
            round,
            clock_ref
        );
    }

    /// -----------------------------
    /// Finalize Round
    /// -----------------------------
    public fun finalize_round(
        registry: &mut OracleRegistry,
        campaign_id: object::ID,
        escrow_id: object::ID,
        milestone_id: u64,
        round: u64,
        clock_ref: &clock::Clock,
        ctx: &tx_context::TxContext
    ): bool {

        let key = round_key(campaign_id, escrow_id, milestone_id, round);
        assert!(table::contains(&registry.rounds, key), E_ROUND_NOT_FOUND);

        let vr = table::borrow_mut(&mut registry.rounds, key);
        assert!(!vr.finalized, E_ROUND_FINALIZED);

        let quorum_reached = vr.total_votes >= vr.quorum;
        assert!(quorum_reached, E_QUORUM_NOT_REACHED);

        let result = vr.approvals > vr.rejections;

        vr.finalized = true;
        vr.finalized_by = tx_context::sender(ctx);

        events::emit_oracle_result(
            campaign_id,
            escrow_id,
            milestone_id,
            round,
            result,
            vr.total_votes,
            vr.approvals,
            clock_ref
        );

        if (result) {
            events::emit_milestone_ready_for_release(
                campaign_id,
                escrow_id,
                milestone_id,
                clock_ref
            );
        };

        result
    }

    /// ✅ REQUIRED BY ESCROW
    public fun is_round_approved(
        registry: &OracleRegistry,
        campaign_id: object::ID,
        escrow_id: object::ID,
        milestone_id: u64,
        round: u64
    ): bool {
        let key = round_key(campaign_id, escrow_id, milestone_id, round);

        if (!table::contains(&registry.rounds, key)) {
            return false
        };

        let vr = table::borrow(&registry.rounds, key);

        (vr.total_votes >= vr.quorum)
            && (vr.approvals > vr.rejections)
            && vr.finalized
    }

    /// -----------------------------
    /// Helpers
    /// -----------------------------
    public fun is_oracle(
        registry: &OracleRegistry,
        oracle_identity: &identity::Identity,
        sender: address
    ): bool {
        let id = object::id(oracle_identity);
        if (!table::contains(&registry.oracles, id)) return false;
        let info = table::borrow(&registry.oracles, id);
        info.owner == sender
    }
}
