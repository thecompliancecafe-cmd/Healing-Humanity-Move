module healing_humanity::reputation {

    use sui::table;
    use sui::clock::Clock;

    use healing_humanity::identity;
    use healing_humanity::identity::Identity;
    use healing_humanity::events;

    use healing_humanity::hypercerts;

    const E_IDENTITY_INACTIVE: u64 = 0;
    const E_NOT_FOUND: u64 = 1;

    /// -----------------------------
    /// XP Struct
    /// -----------------------------
    public struct XP has store {
        owner_identity: object::ID,
        owner_wallet: address,
        xp: u64,
    }

    /// -----------------------------
    /// GLOBAL REGISTRY
    /// -----------------------------
    public struct XPRegistry has key {
        id: object::UID,
        profiles: table::Table<object::ID, XP>,
    }

    /// -----------------------------
    /// Init registry
    /// -----------------------------
    fun init(ctx: &mut tx_context::TxContext) {
        let registry = XPRegistry {
            id: object::new(ctx),
            profiles: table::new(ctx),
        };

        sui::transfer::share_object(registry);
    }

    /// -----------------------------
    /// Create profile
    /// -----------------------------
    public fun create_profile(
        registry: &mut XPRegistry,
        identity: &Identity,
        clock: &Clock,
        _ctx: &mut tx_context::TxContext
    ) {
        assert!(identity::is_active(identity), E_IDENTITY_INACTIVE);

        let id = object::id(identity);

        let xp = XP {
            owner_identity: id,
            owner_wallet: identity::get_owner(identity),
            xp: 0,
        };

        table::add(&mut registry.profiles, id, xp);

        events::emit_reputation_updated(
            identity::get_owner(identity),
            0,
            true,
            b"profile_created",
            id,
            clock
        );
    }

    /// -----------------------------
    /// Add XP
    /// -----------------------------
    public fun add_xp(
        registry: &mut XPRegistry,
        identity: &Identity,
        amount: u64,
        clock: &Clock
    ) {
        let id = object::id(identity);

        assert!(table::contains(&registry.profiles, id), E_NOT_FOUND);

        let xp = table::borrow_mut(&mut registry.profiles, id);

        xp.xp = xp.xp + amount;

        events::emit_reputation_updated(
            identity::get_owner(identity),
            amount,
            true,
            b"xp_gain",
            id,
            clock
        );
    }

    /// -----------------------------
    /// Slash XP
    /// -----------------------------
    public fun slash_xp(
        registry: &mut XPRegistry,
        identity: &Identity,
        amount: u64,
        clock: &Clock
    ) {
        let id = object::id(identity);

        assert!(table::contains(&registry.profiles, id), E_NOT_FOUND);

        let xp = table::borrow_mut(&mut registry.profiles, id);

        let actual_slash;

        if (xp.xp > amount) {
            xp.xp = xp.xp - amount;
            actual_slash = amount;
        } else {
            actual_slash = xp.xp;
            xp.xp = 0;
        };

        events::emit_reputation_updated(
            identity::get_owner(identity),
            actual_slash,
            false,
            b"xp_slash",
            id,
            clock
        );
    }

    /// -----------------------------
    /// 🔥 HYPERCERT: CREATOR REWARD
    /// -----------------------------
    public fun reward_creator_from_hypercert(
        registry: &mut XPRegistry,
        creator_identity: &Identity,
        cert: &hypercerts::Hypercert,
        clock: &Clock
    ) {
        if (!hypercerts::is_verified(cert)) {
            return;
        };

        let impact = hypercerts::get_impact_units(cert);
        let xp_gain = impact;

        add_xp(registry, creator_identity, xp_gain, clock);
    }

    /// -----------------------------
    /// 🔥 HYPERCERT: CONTRIBUTOR REWARD
    /// -----------------------------
    public fun reward_contributor(
        registry: &mut XPRegistry,
        contributor_identity: &Identity,
        units: u64,
        clock: &Clock
    ) {
        let xp_gain = units;
        add_xp(registry, contributor_identity, xp_gain, clock);
    }

    /// -----------------------------
    /// 🔥 HYPERCERT: SLASH ON FRAUD
    /// -----------------------------
    public fun slash_creator_on_revoke(
        registry: &mut XPRegistry,
        creator_identity: &Identity,
        cert: &hypercerts::Hypercert,
        clock: &Clock
    ) {
        let penalty = hypercerts::get_impact_units(cert);
        slash_xp(registry, creator_identity, penalty, clock);
    }

    /// -----------------------------
    /// ✅ NEW: REQUIRED BY ESCROW
    /// -----------------------------
    public fun on_hypercert_verified(
        registry: &mut XPRegistry,
        cert: &hypercerts::Hypercert,
        recipient_identity: &Identity,
        clock: &Clock
    ) {
        // reuse existing logic
        reward_creator_from_hypercert(
            registry,
            recipient_identity,
            cert,
            clock
        );
    }

    /// -----------------------------
    /// Get XP
    /// -----------------------------
    public fun get_xp(
        registry: &XPRegistry,
        identity: &Identity
    ): u64 {
        let id = object::id(identity);

        if (!table::contains(&registry.profiles, id)) {
            return 0
        };

        let xp = table::borrow(&registry.profiles, id);

        xp.xp
    }
}
