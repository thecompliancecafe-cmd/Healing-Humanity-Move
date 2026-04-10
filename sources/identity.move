module healing_humanity::identity {

    use sui::object;
    use sui::tx_context;
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use std::vector;
    use std::string::String;
    use healing_humanity::events;

    /// -----------------------------
    /// Errors
    /// -----------------------------
    const E_IDENTITY_INACTIVE: u64 = 0;
    const E_NOT_OWNER: u64 = 1;
    const E_INVALID_ROLE: u64 = 2;
    const E_NOT_VERIFIED: u64 = 3;
    const E_NOT_AUTHORIZED: u64 = 4;

    /// -----------------------------
    /// Roles
    /// -----------------------------
    const ROLE_USER: u8 = 0;
    const ROLE_BUILDER: u8 = 1;
    const ROLE_ORGANIZATION: u8 = 2;
    const ROLE_AI_AGENT: u8 = 3;
    const ROLE_VERIFIER: u8 = 4;
    const ROLE_ORACLE: u8 = 5;

    /// -----------------------------
    /// Status
    /// -----------------------------
    const STATUS_ACTIVE: u8 = 0;
    const STATUS_SUSPENDED: u8 = 1;

    /// -----------------------------
    /// Identity Object
    /// -----------------------------
    public struct Identity has key {
        id: object::UID,
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
    /// Registry
    /// -----------------------------
    public struct IdentityRegistry has key {
        id: object::UID,
        total_identities: u64
    }

    /// -----------------------------
    /// Admin Cap
    /// -----------------------------
    public struct IdentityAdminCap has key {
        id: object::UID
    }

    /// -----------------------------
    /// Init
    /// -----------------------------
    fun init(ctx: &mut tx_context::TxContext) {
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
    public fun create_identity(
        registry: &mut IdentityRegistry,
        name: String,
        role: u8,
        metadata_url: vector<u8>,
        clock_ref: &Clock,
        ctx: &mut tx_context::TxContext
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
            created_at: clock::timestamp_ms(clock_ref),
            metadata_url,
            delegates: vector::empty<address>()
        };

        registry.total_identities = registry.total_identities + 1;

        /// 🔥 Unified event (bootstrap trace)
        events::emit_reputation_updated(
            sender,
            0,
            true,
            b"identity_created",
            object::id(&identity),
            clock_ref
        );

        transfer::transfer(identity, sender);
    }

    /// -----------------------------
    /// Verify Identity
    /// -----------------------------
    public fun verify_identity(
        identity: &mut Identity,
        _admin: &IdentityAdminCap,
        clock_ref: &Clock,
        ctx: &tx_context::TxContext
    ) {
        assert!(identity.status == STATUS_ACTIVE, E_IDENTITY_INACTIVE);

        identity.verified = true;

        events::emit_identity_verified(
            identity.owner,
            tx_context::sender(ctx),
            1,
            clock_ref
        );
    }

    /// -----------------------------
    /// Update Role
    /// -----------------------------
    public fun update_role(
        identity: &mut Identity,
        new_role: u8,
        _admin: &IdentityAdminCap,
        clock_ref: &Clock
    ) {
        assert!(new_role <= ROLE_ORACLE, E_INVALID_ROLE);

        let old_role = identity.role;
        identity.role = new_role;

        events::emit_reputation_updated(
            identity.owner,
            0,
            true,
            b"role_updated",
            object::id(identity),
            clock_ref
        );
    }

    /// -----------------------------
    /// Suspend Identity
    /// -----------------------------
    public fun suspend_identity(
        identity: &mut Identity,
        _admin: &IdentityAdminCap,
        clock_ref: &Clock
    ) {
        identity.status = STATUS_SUSPENDED;

        events::emit_reputation_updated(
            identity.owner,
            0,
            false,
            b"suspended",
            object::id(identity),
            clock_ref
        );
    }

    /// -----------------------------
    /// Delegation
    /// -----------------------------
    public fun add_delegate(
        identity: &mut Identity,
        delegate: address,
        ctx: &tx_context::TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == identity.owner, E_NOT_OWNER);

        vector::push_back(&mut identity.delegates, delegate);
    }

    public fun remove_delegate(
        identity: &mut Identity,
        delegate: address,
        ctx: &tx_context::TxContext
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
    /// Oracle Helpers
    /// -----------------------------
    public fun assert_valid_oracle_identity(identity: &Identity) {
        assert!(identity.status == STATUS_ACTIVE, E_IDENTITY_INACTIVE);
        assert!(identity.verified, E_NOT_VERIFIED);

        let role = identity.role;
        assert!(role == ROLE_ORACLE || role == ROLE_AI_AGENT, E_INVALID_ROLE);
    }

    public fun is_owner_or_delegate(identity: &Identity, addr: address): bool {
        if (identity.owner == addr) return true;

        let mut i = 0;
        let len = vector::length(&identity.delegates);

        while (i < len) {
            if (*vector::borrow(&identity.delegates, i) == addr) {
                return true
            };
            i = i + 1;
        };

        false
    }

    public fun assert_owner_or_delegate(identity: &Identity, addr: address) {
        assert!(is_owner_or_delegate(identity, addr), E_NOT_AUTHORIZED);
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

    public fun get_owner(identity: &Identity): address {
        identity.owner
    }

    public fun get_role(identity: &Identity): u8 {
        identity.role
    }
}
