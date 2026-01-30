module healing_humanity::reputation {

    /// Soulbound reputation / XP object
    /// Non-transferable by design
    public struct XP has key {
        id: object::UID,
        owner: address,
        xp: u64,
    }

    /// Award XP to an address
    /// XP objects are soulbound (no transfer functions exist)
    public fun award(
        owner: address,
        xp: u64,
        ctx: &mut tx_context::TxContext
    ): XP {
        XP {
            id: object::new(ctx),
            owner,
            xp,
        }
    }
}
