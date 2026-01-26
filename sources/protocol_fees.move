module healing_humanity::protocol_fees {
    public fun calculate(amount: u64, bps: u64): u64 {
        amount * bps / 10_000
    }
}
