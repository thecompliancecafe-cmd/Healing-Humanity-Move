module healing_humanity::hypercerts {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use std::string::String;

    /// Hypercert NFT — proof of impact / donation
    public struct Hypercert has key {
        id: UID,
        donor: address,
        campaign_id: UID,
        metadata: String,
    }

    /// Mint a hypercert NFT
    /// Currently permissionless (can be gated later)
    public fun mint(
        donor: address,
        campaign_id: UID,
        metadata: String,
        ctx: &mut TxContext
    ): Hypercert {
        Hypercert {
            id: sui::object::new(ctx),
            donor,
            campaign_id,
            metadata,
        }
    }
}
