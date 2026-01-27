module healing_humanity::milestone_escrow_tests {
    use sui::test_scenario;
    use sui::coin::{Coin};
    use sui::coin;
    use healing_humanity::milestone_escrow;

    #[test]
    fun test_deposit_and_release() {
        let mut scenario = test_scenario::begin(@0xA);

        let coin: Coin<sui::sui::SUI> =
            test_scenario::take_from_sender(&mut scenario);

        let campaign_id = test_scenario::object_id(&scenario);

        let (vault, cap) =
            milestone_escrow::create(
                campaign_id,
                coin,
                test_scenario::ctx(&mut scenario)
            );

        milestone_escrow::share(vault);

        let deposit_coin: Coin<sui::sui::SUI> =
            test_scenario::take_from_sender(&mut scenario);

        milestone_escrow::deposit(
            test_scenario::borrow_shared(&scenario),
            deposit_coin
        );

        milestone_escrow::release(
            &cap,
            test_scenario::borrow_shared(&scenario),
            1,
            @0xB,
            test_scenario::ctx(&mut scenario)
        );

        test_scenario::end(scenario);
    }
}
