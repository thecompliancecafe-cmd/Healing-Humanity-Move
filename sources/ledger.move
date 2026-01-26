module healing_humanity::ledger {
    struct Entry has store {
        from: address,
        to: address,
        amount: u64,
    }
}
