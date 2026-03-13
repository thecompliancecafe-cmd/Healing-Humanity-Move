module healing_humanity::reputation {

    use healing_humanity::identity;
    use healing_humanity::identity::Identity;

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_IDENTITY_INACTIVE: u64 = 0;

    /// -----------------------------
    /// Soulbound reputation / XP object
    /// Non-transferable by design
    /// -----------------------------
    public struct XP has key {
        id: UID,

        /// Identity that owns the reputation
        owner_identity: ID,

        /// Wallet for reference / indexing
        owner_wallet: address,

        /// Experience points
        xp: u64,
    }

    /// -----------------------------
    /// Award XP to an identity
    /// XP objects remain soulbound
    /// -----------------------------
    public fun award(
        identity: &Identity,
        xp: u64,
        ctx: &mut TxContext
    ): XP {

        // Ensure identity is active
        assert!(
            identity::is_active(identity),
            E_IDENTITY_INACTIVE
        );

        XP {
            id: object::new(ctx),
            owner_identity: object::id(identity),
            owner_wallet: identity::get_owner(identity),
            xp,
        }
    }

    /// -----------------------------
    /// Read Helpers
    /// -----------------------------

    public fun identity_of(xp: &XP): ID {
        xp.owner_identity
    }

    public fun wallet_of(xp: &XP): address {
        xp.owner_wallet
    }

    public fun value(xp: &XP): u64 {
        xp.xp
    }
}
