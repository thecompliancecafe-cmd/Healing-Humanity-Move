module healing_humanity::hypercerts {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use std::string::String;

    struct HyperCert has key {
        id: UID,
        donor: address,
        campaign_id: u64,
        impact: String
    }

    public fun mint(
        donor: address,
        campaign_id: u64,
        impact: String,
        ctx: &mut TxContext
    ): HyperCert {
        HyperCert {
            id: object::new(ctx),
            donor,
            campaign_id,
            impact
        }
    }

    public fun transfer_to(cert: HyperCert, recipient: address) {
        transfer::public_transfer(cert, recipient);
    }
}
