module healing_humanity::hypercerts {
    use std::string::String;

    /// Hypercert NFT — proof of impact / donation
    public struct Hypercert has key {
        id: object::UID,
        donor: address,
        campaign_id: object::ID,
        metadata: String,
    }

    /// Mint a hypercert NFT
    /// Currently permissionless (can be gated later)
    public fun mint(
        donor: address,
        campaign_id: object::ID,
        metadata: String,
        ctx: &mut tx_context::TxContext
    ): Hypercert {
        Hypercert {
            id: object::new(ctx),
            donor,
            campaign_id,
            metadata,
        }
    }
}
