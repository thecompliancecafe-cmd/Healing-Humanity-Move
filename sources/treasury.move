module healing_humanity::treasury {

    use sui::balance;
    use sui::coin::{Self, Coin};
    use sui::event;

    use healing_humanity::circuit_breaker;

    /// =========================
    /// ERRORS
    /// =========================
    const E_INVALID_AMOUNT: u64 = 0;
    const E_WRONG_TREASURY: u64 = 1;
    const E_WITHDRAWALS_PAUSED: u64 = 2;

    /// =========================
    /// EVENTS
    /// =========================
    public struct TreasuryCreatedEvent has copy, drop {
        creator: address,
        treasury_id: sui::object::ID,
        initial_amount: u64,
    }

    public struct TreasuryDepositEvent has copy, drop {
        sender: address,
        amount: u64,
    }

    public struct TreasuryWithdrawEvent has copy, drop {
        recipient: address,
        amount: u64,
    }

    /// =========================
    /// TREASURY STORAGE
    /// =========================
    public struct Treasury has key {
        id: sui::object::UID,
        balance: balance::Balance<sui::sui::SUI>,
    }

    public struct TreasuryCap has key {
        id: sui::object::UID,
        treasury_id: sui::object::ID,
    }

    /// =========================
    /// CREATE TREASURY
    /// =========================
    public fun create(
        initial_coin: Coin<sui::sui::SUI>,
        ctx: &mut TxContext
    ): TreasuryCap {

        let initial_amount = coin::value(&initial_coin);

        let treasury = Treasury {
            id: sui::object::new(ctx),
            balance: coin::into_balance(initial_coin),
        };

        let treasury_id = sui::object::id(&treasury);

        let cap = TreasuryCap {
            id: sui::object::new(ctx),
            treasury_id,
        };

        sui::transfer::share_object(treasury);

        event::emit(TreasuryCreatedEvent {
            creator: tx_context::sender(ctx),
            treasury_id,
            initial_amount
        });

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
            sui::object::id(treasury) == cap.treasury_id,
            E_WRONG_TREASURY
        );
    }

    /// =========================
    /// DEPOSIT (OPEN)
    /// =========================
    public fun deposit(
        treasury: &mut Treasury,
        coin_in: Coin<sui::sui::SUI>,
        ctx: &TxContext
    ) {
        let amount = coin::value(&coin_in);
        assert!(amount > 0, E_INVALID_AMOUNT);

        let bal = coin::into_balance(coin_in);
        balance::join(&mut treasury.balance, bal);

        event::emit(TreasuryDepositEvent {
            sender: tx_context::sender(ctx),
            amount
        });
    }

    /// =========================
    /// WITHDRAW (CB PROTECTED)
    /// =========================
    public fun withdraw(
        cap: &TreasuryCap,
        treasury: &mut Treasury,
        cb: &circuit_breaker::CircuitBreaker,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(
            !circuit_breaker::withdrawals_paused(cb),
            E_WITHDRAWALS_PAUSED
        );

        assert!(amount > 0, E_INVALID_AMOUNT);

        assert_correct_treasury(cap, treasury);

        let bal = balance::split(&mut treasury.balance, amount);
        let coin_out = coin::from_balance(bal, ctx);

        sui::transfer::public_transfer(coin_out, recipient);

        event::emit(TreasuryWithdrawEvent {
            recipient,
            amount
        });
    }

    /// =========================
    /// VIEW BALANCE
    /// =========================
    public fun balance(treasury: &Treasury): u64 {
        balance::value(&treasury.balance)
    }
}
