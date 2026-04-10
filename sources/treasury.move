module healing_humanity::treasury {

    use sui::balance;
    use sui::coin::{Self, Coin};
    use sui::object;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::Clock;

    use std::option;

    use healing_humanity::circuit_breaker;
    use healing_humanity::protocol_governance;
    use healing_humanity::events;

    /// =========================
    /// ERRORS
    /// =========================
    const E_INVALID_AMOUNT: u64 = 0;
    const E_WRONG_TREASURY: u64 = 1;
    const E_WITHDRAWALS_PAUSED: u64 = 2;
    const E_INVALID_RECIPIENT: u64 = 3;

    /// =========================
    /// TREASURY STORAGE
    /// =========================
    public struct Treasury has key {
        id: object::UID,
        balance: balance::Balance<sui::sui::SUI>,
    }

    public struct TreasuryCap has key {
        id: object::UID,
        treasury_id: object::ID,
    }

    /// =========================
    /// CREATE TREASURY
    /// =========================
    public fun create(
        initial_coin: Coin<sui::sui::SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): TreasuryCap {

        let initial_amount = coin::value(&initial_coin);

        let treasury = Treasury {
            id: object::new(ctx),
            balance: coin::into_balance(initial_coin),
        };

        let treasury_id = object::id(&treasury);

        let cap = TreasuryCap {
            id: object::new(ctx),
            treasury_id,
        };

        sui::transfer::share_object(treasury);

        /// 🔥 FIXED: pass clock instead of ctx
        events::emit_treasury_deposit(
            b"treasury_create",
            initial_amount,
            option::none(),
            clock
        );

        cap
    }

    /// =========================
    /// INTERNAL CHECK
    /// =========================
    fun assert_correct_treasury(
        cap: &TreasuryCap,
        treasury: &Treasury
    ) {
        assert!(
            object::id(treasury) == cap.treasury_id,
            E_WRONG_TREASURY
        );
    }

    /// =========================
    /// DEPOSIT (OPEN)
    /// =========================
    public fun deposit(
        cfg: &protocol_governance::ProtocolConfig,
        treasury: &mut Treasury,
        coin_in: Coin<sui::sui::SUI>,
        clock: &Clock,
        ctx: &TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);

        let amount = coin::value(&coin_in);
        assert!(amount > 0, E_INVALID_AMOUNT);

        let bal = coin::into_balance(coin_in);
        balance::join(&mut treasury.balance, bal);

        events::emit_treasury_deposit(
            b"user_deposit",
            amount,
            option::none(),
            clock
        );
    }

    /// =========================
    /// WITHDRAW (CB + GOV)
    /// =========================
    public fun withdraw(
        cfg: &protocol_governance::ProtocolConfig,
        cap: &TreasuryCap,
        treasury: &mut Treasury,
        cb: &circuit_breaker::CircuitBreaker,
        amount: u64,
        recipient: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        protocol_governance::assert_protocol_active(cfg);

        assert!(
            !circuit_breaker::withdrawals_paused(cb),
            E_WITHDRAWALS_PAUSED
        );

        assert!(amount > 0, E_INVALID_AMOUNT);

        assert_correct_treasury(cap, treasury);

        let treasury_addr = protocol_governance::treasury(cfg);
        assert!(recipient == treasury_addr, E_INVALID_RECIPIENT);

        let bal = balance::split(&mut treasury.balance, amount);
        let coin_out = coin::from_balance(bal, ctx);

        sui::transfer::public_transfer(coin_out, recipient);

        events::emit_treasury_deposit(
            b"withdraw",
            amount,
            option::none(),
            clock
        );
    }

    /// =========================
    /// VIEW BALANCE
    /// =========================
    public fun balance(treasury: &Treasury): u64 {
        balance::value(&treasury.balance)
    }
}
