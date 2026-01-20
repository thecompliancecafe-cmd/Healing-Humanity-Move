module healing_humanity::treasury {

    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use std::vector;

    struct Treasury has key {
        id: UID,
        signers: vector<address>,
        threshold: u64,
        balance: Balance<SUI>,
    }

    struct Proposal has key {
        id: UID,
        to: address,
        amount: u64,
        approvals: vector<address>,
        executed: bool,
    }

    public fun init(signers: vector<address>, threshold: u64, ctx: &mut TxContext): Treasury {
        Treasury {
            id: object::new(ctx),
            signers,
            threshold,
            balance: balance::zero(),
        }
    }

    public fun deposit(treasury: &mut Treasury, coin: Coin<SUI>) {
        balance::join(&mut treasury.balance, coin::into_balance(coin));
    }

    public fun propose_payout(
        to: address,
        amount: u64,
        ctx: &mut TxContext
    ): Proposal {
        Proposal {
            id: object::new(ctx),
            to,
            amount,
            approvals: vector::empty(),
            executed: false,
        }
    }

    public fun approve(
        treasury: &Treasury,
        proposal: &mut Proposal,
        signer: &signer
    ) {
        let addr = signer::address_of(signer);
        assert!(vector::contains(&treasury.signers, addr), 0);
        vector::push_back(&mut proposal.approvals, addr);
    }

    public fun execute(
        treasury: &mut Treasury,
        proposal: &mut Proposal,
        ctx: &mut TxContext
    ) {
        assert!(vector::length(&proposal.approvals) >= treasury.threshold, 1);

        let payout = balance::split(&mut treasury.balance, proposal.amount);
        let coin = coin::from_balance(payout, ctx);
        transfer::public_transfer(coin, proposal.to);

        proposal.executed = true;
    }
}
