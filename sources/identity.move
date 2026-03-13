module healing_humanity::identity {

    use sui::event;
    use sui::clock::{Self, Clock};
    use std::string::String;

    /// -----------------------------
    /// Errors
    /// -----------------------------

    const E_IDENTITY_INACTIVE: u64 = 0;
    const E_NOT_OWNER: u64 = 1;
    const E_INVALID_ROLE: u64 = 2;

    /// -----------------------------
    /// Role Definitions
    /// -----------------------------

    const ROLE_USER: u8 = 0;
    const ROLE_BUILDER: u8 = 1;
    const ROLE_ORGANIZATION: u8 = 2;
    const ROLE_AI_AGENT: u8 = 3;
    const ROLE_VERIFIER: u8 = 4;
    const ROLE_ORACLE: u8 = 5;

    /// -----------------------------
    /// Status Definitions
    /// -----------------------------

    const STATUS_ACTIVE: u8 = 0;
    const STATUS_SUSPENDED: u8 = 1;

    /// -----------------------------
    /// Identity Object
    /// -----------------------------

    public struct Identity has key {
        id: UID,
        owner: address,
        name: String,
        role: u8,
        status: u8,
        verified: bool,
        reputation_score: u64,
        created_at: u64,
        metadata_url: vector<u8>,
        delegates: vector<address>
    }

    /// -----------------------------
    /// Identity Registry
    /// -----------------------------

    public struct IdentityRegistry has key {
        id: UID,
        total_identities: u64
    }

    /// -----------------------------
    /// Admin Capability
    /// -----------------------------

    public struct IdentityAdminCap has key {
        id: UID
    }

    /// -----------------------------
    /// Events
    /// -----------------------------

    public struct IdentityCreated has copy, drop {
        identity_id: ID,
        owner: address,
        role: u8,
        timestamp: u64
    }

    public struct IdentityVerified has copy, drop {
        identity_id: ID,
        verifier: address,
        timestamp: u64
    }

    public struct IdentityRoleUpdated has copy, drop {
        identity_id: ID,
        old_role: u8,
        new_role: u8
    }

    public struct IdentitySuspended has copy, drop {
        identity_id: ID,
        timestamp: u64
    }

    /// -----------------------------
    /// Initialize Registry
    /// -----------------------------

    fun init(ctx: &mut TxContext) {

        let registry = IdentityRegistry {
            id: object::new(ctx),
            total_identities: 0
        };

        let admin_cap = IdentityAdminCap {
            id: object::new(ctx)
        };

        transfer::share_object(registry);
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// -----------------------------
    /// Create Identity
    /// -----------------------------

    public entry fun create_identity(
        registry: &mut IdentityRegistry,
        name: String,
        role: u8,
        metadata_url: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {

        assert!(role <= ROLE_ORACLE, E_INVALID_ROLE);

        let sender = tx_context::sender(ctx);

        let identity = Identity {
            id: object::new(ctx),
            owner: sender,
            name,
            role,
            status: STATUS_ACTIVE,
            verified: false,
            reputation_score: 0,
            created_at: clock::timestamp_ms(clock),
            metadata_url,
            delegates: vector::empty<address>()
        };

        registry.total_identities = registry.total_identities + 1;

        event::emit(IdentityCreated {
            identity_id: object::id(&identity),
            owner: sender,
            role,
            timestamp: clock::timestamp_ms(clock)
        });

        transfer::transfer(identity, sender);
    }

    /// -----------------------------
    /// Verify Identity
    /// -----------------------------

    public entry fun verify_identity(
        identity: &mut Identity,
        _admin: &IdentityAdminCap,
        clock: &Clock,
        ctx: &TxContext
    ) {

        assert!(identity.status == STATUS_ACTIVE, E_IDENTITY_INACTIVE);

        identity.verified = true;

        event::emit(IdentityVerified {
            identity_id: object::id(identity),
            verifier: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock)
        });
    }

    /// -----------------------------
    /// Update Role
    /// -----------------------------

    public entry fun update_role(
        identity: &mut Identity,
        new_role: u8,
        _admin: &IdentityAdminCap
    ) {

        assert!(new_role <= ROLE_ORACLE, E_INVALID_ROLE);

        let old_role = identity.role;
        identity.role = new_role;

        event::emit(IdentityRoleUpdated {
            identity_id: object::id(identity),
            old_role,
            new_role
        });
    }

    /// -----------------------------
    /// Suspend Identity
    /// -----------------------------

    public entry fun suspend_identity(
        identity: &mut Identity,
        _admin: &IdentityAdminCap,
        clock: &Clock
    ) {

        identity.status = STATUS_SUSPENDED;

        event::emit(IdentitySuspended {
            identity_id: object::id(identity),
            timestamp: clock::timestamp_ms(clock)
        });
    }

    /// -----------------------------
    /// Delegate Management
    /// -----------------------------

    public entry fun add_delegate(
        identity: &mut Identity,
        delegate: address,
        ctx: &TxContext
    ) {

        let sender = tx_context::sender(ctx);
        assert!(sender == identity.owner, E_NOT_OWNER);

        vector::push_back(&mut identity.delegates, delegate);
    }

    public entry fun remove_delegate(
        identity: &mut Identity,
        delegate: address,
        ctx: &TxContext
    ) {

        let sender = tx_context::sender(ctx);
        assert!(sender == identity.owner, E_NOT_OWNER);

        let mut i = 0;
        let len = vector::length(&identity.delegates);

        while (i < len) {
            if (*vector::borrow(&identity.delegates, i) == delegate) {
                vector::swap_remove(&mut identity.delegates, i);
                break
            };
            i = i + 1;
        };
    }

    /// -----------------------------
    /// Helpers
    /// -----------------------------

    public fun is_verified(identity: &Identity): bool {
        identity.verified
    }

    public fun is_active(identity: &Identity): bool {
        identity.status == STATUS_ACTIVE
    }

    public fun is_ai(identity: &Identity): bool {
        identity.role == ROLE_AI_AGENT
    }

    public fun is_oracle(identity: &Identity): bool {
        identity.role == ROLE_ORACLE
    }

    public fun is_builder(identity: &Identity): bool {
        identity.role == ROLE_BUILDER
    }

    public fun is_organization(identity: &Identity): bool {
        identity.role == ROLE_ORGANIZATION
    }

    public fun get_owner(identity: &Identity): address {
        identity.owner
    }

    public fun get_role(identity: &Identity): u8 {
        identity.role
    }
}
