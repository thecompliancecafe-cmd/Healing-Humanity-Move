module healing_humanity::ai_oracle {

    use std::string;

    use sui::event;
    use sui::clock;
    use sui::table;

    use healing_humanity::identity;
    use healing_humanity::circuit_breaker;
    use healing_humanity::ai_attestation;

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_ALREADY_ORACLE: u64 = 0;
    const E_NOT_FOUND: u64 = 1;
    const E_PAUSED: u64 = 2;
    const E_RATE_LIMIT: u64 = 3;
    const E_NOT_ORACLE: u64 = 4;

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
    /// Registry
    /// -----------------------------
    public struct OracleRegistry has key {
        id: object::UID,
        oracles: table::Table<object::ID, OracleInfo>,
        oracle_count: u64,
    }

    /// -----------------------------
    /// Admin capability
    /// -----------------------------
    public struct OracleAdminCap has key {
        id: object::UID,
    }

    /// -----------------------------
    /// Events
    /// -----------------------------
    public struct OracleAdded has copy, drop {
        identity_id: object::ID,
        owner: address,
        timestamp: u64,
    }

    public struct OracleRemoved has copy, drop {
        identity_id: object::ID,
        owner: address,
        timestamp: u64,
    }

    /// -----------------------------
    /// Init
    /// -----------------------------
    fun init(ctx: &mut tx_context::TxContext) {
        let registry = OracleRegistry {
            id: object::new(ctx),
            oracles: table::new(ctx),
            oracle_count: 0,
        };

        transfer::share_object(registry);
    }

    /// -----------------------------
    /// Create admin cap
    /// -----------------------------
    public fun create_admin_cap(ctx: &mut tx_context::TxContext) {
        let cap = OracleAdminCap {
            id: object::new(ctx),
        };

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
        cb: &circuit_breaker::CircuitBreaker,
        clock_ref: &clock::Clock,
        ctx: &tx_context::TxContext
    ) {
        assert!(!circuit_breaker::is_paused(cb), E_PAUSED);

        let sender = tx_context::sender(ctx);

        identity::assert_valid_oracle_identity(oracle_identity);
        identity::assert_owner_or_delegate(oracle_identity, sender);

        let id = object::id(oracle_identity);

        assert!(!table::contains(&registry.oracles, id), E_ALREADY_ORACLE);

        let now = clock::timestamp_ms(clock_ref);

        let info = OracleInfo {
            owner: identity::get_owner(oracle_identity),
            added_at: now,
            reputation: 0,
            last_submission: 0,
            endpoint,
            pubkey,
            model,
        };

        table::add(&mut registry.oracles, id, info);
        registry.oracle_count = registry.oracle_count + 1;

        event::emit(OracleAdded {
            identity_id: id,
            owner: identity::get_owner(oracle_identity),
            timestamp: now,
        });
    }

    /// -----------------------------
    /// Submit Attestation
    /// -----------------------------
    public fun submit_attestation(
        registry: &mut OracleRegistry,
        oracle_identity: &identity::Identity,
        campaign_id: object::ID,
        milestone: u64,
        hash: string::String,
        cb: &circuit_breaker::CircuitBreaker,
        clock_ref: &clock::Clock,
        ctx: &mut tx_context::TxContext
    ): ai_attestation::Attestation {

        assert!(!circuit_breaker::is_paused(cb), E_PAUSED);

        let sender = tx_context::sender(ctx);

        assert!(
            is_oracle(registry, oracle_identity, sender),
            E_NOT_ORACLE
        );

        let min_interval = 5000;
        assert_rate_limit(registry, oracle_identity, min_interval, clock_ref);

        update_submission_time(registry, oracle_identity, clock_ref);

        let id = object::id(oracle_identity);
        let info = table::borrow_mut(&mut registry.oracles, id);
        info.reputation = info.reputation + 1;

        ai_attestation::submit_internal(
            oracle_identity,
            campaign_id,
            milestone,
            hash,
            ctx
        )
    }

    /// -----------------------------
    /// Rate Limit
    /// -----------------------------
    public fun assert_rate_limit(
        registry: &OracleRegistry,
        oracle_identity: &identity::Identity,
        min_interval_ms: u64,
        clock_ref: &clock::Clock
    ) {
        let id = object::id(oracle_identity);

        assert!(table::contains(&registry.oracles, id), E_NOT_FOUND);

        let info = table::borrow(&registry.oracles, id);
        let now = clock::timestamp_ms(clock_ref);

        assert!(now >= info.last_submission + min_interval_ms, E_RATE_LIMIT);
    }

    /// -----------------------------
    /// Update Timestamp
    /// -----------------------------
    public fun update_submission_time(
        registry: &mut OracleRegistry,
        oracle_identity: &identity::Identity,
        clock_ref: &clock::Clock
    ) {
        let id = object::id(oracle_identity);

        let info = table::borrow_mut(&mut registry.oracles, id);
        info.last_submission = clock::timestamp_ms(clock_ref);
    }

    /// -----------------------------
    /// Check Oracle (FULL VALIDATION)
    /// -----------------------------
    public fun is_oracle(
        registry: &OracleRegistry,
        oracle_identity: &identity::Identity,
        sender: address
    ): bool {
        let id = object::id(oracle_identity);

        if (!table::contains(&registry.oracles, id)) {
            return false
        };

        let info = table::borrow(&registry.oracles, id);
        info.owner == sender
    }

    /// -----------------------------
    /// Check Oracle by ID (for escrow)
    /// -----------------------------
    public fun is_oracle_id(
        registry: &OracleRegistry,
        id: object::ID
    ): bool {
        table::contains(&registry.oracles, id)
    }
}
