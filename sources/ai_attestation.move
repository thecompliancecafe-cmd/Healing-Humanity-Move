module healing_humanity::ai_attestation {
    use sui::tx_context::TxContext;

    struct Attestation has store {
        oracle: address,
        approved: bool,
    }

    public fun submit(ctx: &TxContext, approved: bool): Attestation {
        Attestation {
            oracle: tx_context::sender(ctx),
            approved,
        }
    }
}
