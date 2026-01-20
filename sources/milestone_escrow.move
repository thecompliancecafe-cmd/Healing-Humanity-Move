module healing_humanity::milestone_escrow {

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::coin::{Self, Coin};
    use sui::transfer;

    struct EscrowVault has key {
        id: UID,
        campaign_id: u64,
        balance: Coin<SUI>,
        released_percent: u8
    }

    public fun create_vault(
        campaign_id: u64,
        initial_funds: Coin<SUI>,
        ctx: &mut TxContext
    ): EscrowVault {
        EscrowVault {
            id: object::new(ctx),
            campaign_id,
            balance: initial_funds,
            released_percent: 0
        }
    }

    public fun deposit(vault: &mut EscrowVault, funds: Coin<SUI>) {
        coin::merge(&mut vault.balance, funds);
    }

    public fun release(
        vault: &mut EscrowVault,
        percent: u8,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(percent > vault.released_percent, 1);

        let amount = coin::value(&vault.balance) * (percent as u64) / 100;
        let payout = coin::split(&mut vault.balance, amount, ctx);

        vault.released_percent = percent;
        transfer::public_transfer(payout, recipient);
    }
}
