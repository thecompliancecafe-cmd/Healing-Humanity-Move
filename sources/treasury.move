module healing_humanity::milestone_escrow_tests {
    use sui::test_scenario;
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::transfer;

    use healing_humanity::milestone_escrow;
    use healing_humanity::protocol_governance;

    #[test]
    fun test_deposit_and_release() {
        let mut scenario = test_scenario::begin(@0xA);
        let ctx = test_scenario::ctx(&mut scenario);

        /* ---------------- Governance ---------------- */

        let (mut cfg, gov_cap) =
            protocol_governance::init_for_testing(ctx);

        /* ---------------- Campaign ---------------- */

        let campaign_uid = sui::object::new(ctx);
        let campaign_id = sui::object::uid_to_inner(&campaign_uid);

        /* ---------------- Escrow ---------------- */

        let (vault, escrow_cap) =
            milestone_escrow::create(campaign_id, ctx);

        transfer::share_object(vault);

        let vault_ref =
            test_scenario::borrow_shared_mut<
                milestone_escrow::Vault
            >(&mut scenario);

        /* ---------------- Deposit ---------------- */

        let deposit_coin: Coin<SUI> =
            test_scenario::take_from_sender(&mut scenario);

        milestone_escrow::deposit(
            vault_ref,
            deposit_coin
        );

        /* ---------------- Release ---------------- */

        milestone_escrow::release(
            &escrow_cap,
            &cfg,
            vault_ref,
            1,
            @0xB,
            ctx
        );

        test_scenario::end(scenario);
    }
}
