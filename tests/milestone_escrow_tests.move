module healing_humanity::milestone_escrow_tests {

    use sui::test_scenario;
    use sui::coin::{Coin};
    use sui::sui::SUI;

    use healing_humanity::milestone_escrow;

    #[test]
    fun test_create_and_release() {
        let mut scenario = test_scenario::begin(@0xA);

        // ─────────────────────────────────────────────
        // Step 1: get ctx
        // ─────────────────────────────────────────────
        let ctx = test_scenario::ctx(&mut scenario);

        // Create a test coin
        let coin: Coin<SUI> = test_scenario::mint_sui_for_testing(10, ctx);

        // ─────────────────────────────────────────────
        // Step 2: create escrow
        // ─────────────────────────────────────────────
        let (vault, cap) =
            milestone_escrow::create(
                sui::object::new(ctx),
                coin,
                ctx
            );

        // ─────────────────────────────────────────────
        // Step 3: release funds
        // ─────────────────────────────────────────────
        milestone_escrow::release(
            &cap,
            vault,
            5u64,
            @0xB,
            ctx
        );

        // ─────────────────────────────────────────────
        // Step 4: consume remaining objects
        // ─────────────────────────────────────────────
        // cap is an object → must be transferred
        sui::transfer::transfer(cap, @0xA);

        // End scenario AFTER all objects are consumed
        test_scenario::end(scenario);
    }
}
