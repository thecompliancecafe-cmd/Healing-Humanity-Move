module healing_humanity::identity {
    use std::string::String;

    /// On-chain identity object (NGO / individual)
    public struct Identity has key {
        id: UID,
        name: String,
        wallet: address,
    }

    /// Create a new identity
    /// NOTE: currently permissionless (anyone can create)
    public fun create(
        name: String,
        wallet: address,
        ctx: &mut TxContext
    ): Identity {
        Identity {
            id: object::new(ctx),
            name,
            wallet,
        }
    }
}
