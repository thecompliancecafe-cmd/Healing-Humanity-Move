module healing_humanity::milestone_escrow_tests {

    use sui::test_scenario;
    use sui::coin::Coin;
    use sui::sui::SUI;

    use healing_humanity::milestone_escrow;

    #[test]
    fun test_deposit_and_release() {

        // Start test scenario
        let mut scenario = test_scenario::begin(@0xA);
        let ctx = test_scenario::ctx(&mut scenario);

        // Create a fake campaign id
        let campaign_uid = sui::object::new(ctx);
        let campaign_id = sui::object::uid_to_inner(&campaign_uid);

        // Take coin from sender
        let coin: Coin<SUI> =
            test_scenario::take_from_sender(&mut scenario);

        // Create escrow
        // NOTE: vault is already shared inside create()
        let (mut vault, cap) =
            milestone_escrow::create(
                campaign_id,
                coin,
                ctx
            );

        // Deposit more funds
        let extra_coin: Coin<SUI> =
            test_scenario::take_from_sender(&mut scenario);

        milestone_escrow::deposit(
            &mut vault,
            extra_coin
        );

        // Release funds
        milestone_escrow::release(
            &cap,
            &mut vault,
            1u64,
            @0xB,
            ctx
        );

        // End scenario
        test_scenario::end(scenario);
    }
}
