module healing_humanity::events {
    use sui::event;
    use std::string::String;

    struct CampaignCreated has copy, drop {
        name: String,
    }

    struct DonationReceived has copy, drop {
        campaign: String,
        amount: u64,
    }

    public fun campaign_created(name: String) {
        event::emit(CampaignCreated { name });
    }

    public fun donation_received(campaign: String, amount: u64) {
        event::emit(DonationReceived { campaign, amount });
    }
}
