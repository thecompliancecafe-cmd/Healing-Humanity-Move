module healing_humanity::reputation {

    use sui::table;
    use sui::clock::Clock;

    use healing_humanity::identity;
    use healing_humanity::identity::Identity;
    use healing_humanity::events;

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

        // EVENT
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

        // EVENT
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

        // EVENT
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
