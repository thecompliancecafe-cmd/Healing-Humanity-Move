module healing_humanity::milestone_escrow {
    use sui::object::{UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::event;

    use healing_humanity::protocol_governance::{Self, ProtocolConfig};

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
        balance: Balance,
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
                id: UID::new(ctx),
                campaign_id,
                balance: balance::zero(),
            },
            EscrowAdminCap {
                id: UID::new(ctx),
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
        coin_in: Coin<sui::sui::SUI>
    ) {
        let amount = coin::value(&coin_in);
        balance::deposit(&mut vault.balance, coin_in);

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
        recipient: address,
        ctx: &mut TxContext
    ) {
        // Governance safety check
        assert!(!protocol_governance::is_paused(cfg), 0);

        let coin_out = balance::withdraw(
            &mut vault.balance,
            amount,
            ctx
        );

        transfer::public_transfer(coin_out, recipient);

        event::emit(FundsReleased {
            vault_id: object::id(vault),
            recipient,
            amount,
        });
    }
}
