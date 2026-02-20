module healing_humanity::treasury {

    use sui::balance;
    use sui::coin::{Self, Coin};
    use sui::event;

    /// =========================
    /// ERRORS
    /// =========================
    const E_INVALID_AMOUNT: u64 = 0;
    const E_WRONG_TREASURY: u64 = 1;

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

    /// Admin capability bound to a specific treasury
    public struct TreasuryCap has key {
        id: sui::object::UID,
        treasury_id: sui::object::ID,
    }

    /// =========================
    /// CREATE TREASURY
    /// =========================
    public fun create(
        initial_coin: Coin<sui::sui::SUI>,
        ctx: &mut sui::tx_context::TxContext
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

        // Share treasury
        sui::transfer::share_object(treasury);

        event::emit(TreasuryCreatedEvent {
            creator: sui::tx_context::sender(ctx),
            treasury_id,
            initial_amount
        });

        cap
    }

    /// =========================
    /// INTERNAL TREASURY MATCH CHECK
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
    /// DEPOSIT (OPEN TO ANYONE)
    /// =========================
    public fun deposit(
        treasury: &mut Treasury,
        coin_in: Coin<sui::sui::SUI>,
        ctx: &sui::tx_context::TxContext
    ) {
        let amount = coin::value(&coin_in);
        assert!(amount > 0, E_INVALID_AMOUNT);

        let bal = coin::into_balance(coin_in);
        balance::join(&mut treasury.balance, bal);

        event::emit(TreasuryDepositEvent {
            sender: sui::tx_context::sender(ctx),
            amount
        });
    }

    /// =========================
    /// WITHDRAW (CAP REQUIRED)
    /// =========================
    public fun withdraw(
        cap: &TreasuryCap,
        treasury: &mut Treasury,
        amount: u64,
        recipient: address,
        ctx: &mut sui::tx_context::TxContext
    ) {
        assert!(amount > 0, E_INVALID_AMOUNT);

        // Ensure cap matches treasury
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
