module healing_humanity::events {
    use sui::event;
    use std::string;

    /// Emitted when a new campaign is created
    public struct CampaignCreated has copy, drop {
        name: string::String,
    }

    /// Emitted when a donation is received
    public struct DonationReceived has copy, drop {
        campaign: string::String,
        amount: u64,
    }

    /// Emit campaign creation event
    public fun emit_campaign_created(name: string::String) {
        event::emit(CampaignCreated { name });
    }

    /// Emit donation received event
    public fun emit_donation_received(
        campaign: string::String,
        amount: u64
    ) {
        event::emit(DonationReceived { campaign, amount });
    }
}
