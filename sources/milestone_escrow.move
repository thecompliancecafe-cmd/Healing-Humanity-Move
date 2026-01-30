module healing_humanity::milestone_escrow {
    use sui::object::{self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::balance::Balance;
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::event;

    use healing_humanity::protocol_governance::{self, ProtocolConfig};

    /// Event: funds deposited
    public struct FundsDeposited has copy, drop {
        vault_id: ID,
        amount: u64,
    }

    /// Event: funds released
    public struct FundsReleased has copy, drop {
        vault_id: ID,
        recipient: address,
        amount: u64,
    }

    /// SHARED escrow vault (SUI only)
    public struct Vault has key {
        id: UID,
        campaign_id: ID,
        balance: Balance<SUI>,
    }

    /// Capability required to release funds
    public struct EscrowAdminCap has key {
        id: UID,
    }

    /// Create vault + admin capability
    public fun create(
        campaign_id: ID,
        ctx: &mut TxContext
    ): (Vault, EscrowAdminCap) {
        (
            Vault {
                id: object::new(ctx),
                campaign_id,
                balance: Balance::zero(),
            },
            EscrowAdminCap {
                id: object::new(ctx),
            }
        )
    }

    /// Share vault so anyone can deposit
    public fun share(vault: Vault) {
        transfer::share_object(vault);
    }

    /// Deposit SUI into vault (permissionless)
    public fun deposit(
        vault: &mut Vault,
        coin_in: Coin<SUI>
    ) {
        let amount = coin_in.value();
        vault.balance.join(coin_in);

        event::emit(FundsDeposited {
            vault_id: object::id(vault),
            amount,
        });
    }

    /// Release funds (ADMIN ONLY, protocol must be active)
    public fun release(
        _admin: &EscrowAdminCap,
        cfg: &ProtocolConfig,
        vault: &mut Vault,
        amount: u64,
        recipient: address
    ) {
        // Governance safety check
        assert!(!protocol_governance::is_paused(cfg), 0);

        let coin_out = vault.balance.split(amount);
        transfer::public_transfer(coin_out, recipient);

        event::emit(FundsReleased {
            vault_id: object::id(vault),
            recipient,
            amount,
        });
    }
}
