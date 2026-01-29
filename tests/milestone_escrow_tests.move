module healing_humanity::milestone_escrow_tests {
    use sui::test_scenario;
    use sui::coin::{Coin};
    use sui::sui::SUI;
    use healing_humanity::milestone_escrow;

    #[test]
    fun test_deposit_and_release() {
        let mut scenario = test_scenario::begin(@0xA);

        let ctx = test_scenario::ctx(&mut scenario);

        // Initial funding coin
        let coin: Coin<SUI> =
            test_scenario::take_from_sender(&mut scenario);

        // Dummy campaign object ID
        let campaign_uid = sui::object::new(ctx);
        let campaign_id = sui::object::uid_to_inner(&campaign_uid);

        // Create vault + admin cap
        let (vault, cap) =
            milestone_escrow::create(
                campaign_id,
                coin,
                ctx
            );

        // Share the vault
        sui::transfer::share_object(vault);

        // Borrow shared vault mutably
        let vault_ref =
            test_scenario::borrow_shared_mut<
                milestone_escrow::Vault<SUI>
            >(&mut scenario);

        // Deposit additional funds
        let deposit_coin: Coin<SUI> =
            test_scenario::take_from_sender(&mut scenario);

        milestone_escrow::deposit(
            vault_ref,
            deposit_coin
        );

        // Release funds
        milestone_escrow::release(
            &cap,
            vault_ref,
            1,
            @0xB,
            ctx
        );

        test_scenario::end(scenario);
    }
}
