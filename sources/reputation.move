module healing_humanity::reputation {
    use sui::object::UID;
    use sui::tx_context::TxContext;

    /// Soulbound reputation / XP object
    /// Non-transferable by design
    public struct XP has key {
        id: UID,
        owner: address,
        xp: u64,
    }

    /// Award XP to an address
    /// XP objects are soulbound (no transfer functions exist)
    public fun award(
        owner: address,
        xp: u64,
        ctx: &mut TxContext
    ): XP {
        XP {
            id: UID::new(ctx),
            owner,
            xp,
        }
    }
}
