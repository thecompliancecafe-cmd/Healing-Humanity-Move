module healing_humanity::milestone_escrow {
    use sui::object::{UID, ID, object};
    use sui::coin::{Coin};
    use sui::tx_context::TxContext;
    use sui::coin;

    struct Vault<T> has key {
        id: UID,
        campaign_id: ID,
        funds: Coin<T>,
    }

    public fun create<T>(
        campaign_id: ID,
        coin: Coin<T>,
        ctx: &mut TxContext
    ): Vault<T> {
        Vault {
            id: object::new(ctx),
            campaign_id,
            funds: coin,
        }
    }

    public fun deposit<T>(vault: &mut Vault<T>, coin_in: Coin<T>) {
        coin::merge(&mut vault.funds, coin_in);
    }
}
