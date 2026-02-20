module healing_humanity::access_control {

    use sui::table::{Self, Table};
    use sui::event;

    /// =========================
    /// ERRORS
    /// =========================
    const E_PROTOCOL_PAUSED: u64 = 1;

    /// =========================
    /// EVENTS
    /// =========================
    public struct RoleGrantedEvent has copy, drop {
        role: vector<u8>,
        account: address,
    }

    public struct RoleRevokedEvent has copy, drop {
        role: vector<u8>,
        account: address,
    }

    public struct ProtocolPausedEvent has copy, drop {
        paused: bool,
    }

    /// =========================
    /// SHARED ROLE REGISTRY
    /// =========================
    public struct Roles has key {
        id: UID,
        oracles: Table<address, bool>,
        compliance: Table<address, bool>,
        auditors: Table<address, bool>,
        treasury_signers: Table<address, bool>,
        paused: bool,
    }

    /// Admin capability
    public struct AdminCap has key {
        id: UID,
    }

    /// =========================
    /// INIT (called at publish)
    /// =========================
    fun init(ctx: &mut TxContext) {
        let roles = Roles {
            id: object::new(ctx),
            oracles: table::new(ctx),
            compliance: table::new(ctx),
            auditors: table::new(ctx),
            treasury_signers: table::new(ctx),
            paused: false,
        };

        let admin = AdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(roles);
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    /// =========================
    /// INTERNAL ADMIN CHECK
    /// =========================
    fun assert_admin(_admin: &AdminCap) {
        // Possession of AdminCap is authority
        // If function is callable, admin owns cap
    }

    /// =========================
    /// PAUSE / UNPAUSE PROTOCOL
    /// =========================
    public fun set_pause(
        _admin: &AdminCap,
        roles: &mut Roles,
        value: bool
    ) {
        roles.paused = value;

        event::emit(ProtocolPausedEvent {
            paused: value
        });
    }

    public fun assert_not_paused(roles: &Roles) {
        assert!(!roles.paused, E_PROTOCOL_PAUSED);
    }

    /// =========================
    /// GENERIC ROLE HELPERS
    /// =========================
    fun grant_role(
        table_ref: &mut Table<address, bool>,
        role_name: vector<u8>,
        account: address
    ) {
        if (!table::contains(table_ref, account)) {
            table::add(table_ref, account, true);
            event::emit(RoleGrantedEvent { role: role_name, account });
        }
    }

    fun revoke_role(
        table_ref: &mut Table<address, bool>,
        role_name: vector<u8>,
        account: address
    ) {
        if (table::contains(table_ref, account)) {
            table::remove(table_ref, account);
            event::emit(RoleRevokedEvent { role: role_name, account });
        }
    }

    fun has_role(
        table_ref: &Table<address, bool>,
        account: address
    ): bool {
        table::contains(table_ref, account)
    }

    /// =========================
    /// ORACLE ROLE
    /// =========================
    public fun add_oracle(
        admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        assert_admin(admin);
        grant_role(&mut roles.oracles, b"ORACLE", addr);
    }

    public fun remove_oracle(
        admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        assert_admin(admin);
        revoke_role(&mut roles.oracles, b"ORACLE", addr);
    }

    public fun is_oracle(
        roles: &Roles,
        addr: address
    ): bool {
        has_role(&roles.oracles, addr)
    }

    /// =========================
    /// COMPLIANCE ROLE
    /// =========================
    public fun add_compliance(
        admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        assert_admin(admin);
        grant_role(&mut roles.compliance, b"COMPLIANCE", addr);
    }

    public fun remove_compliance(
        admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        assert_admin(admin);
        revoke_role(&mut roles.compliance, b"COMPLIANCE", addr);
    }

    public fun is_compliance(
        roles: &Roles,
        addr: address
    ): bool {
        has_role(&roles.compliance, addr)
    }

    /// =========================
    /// AUDITOR ROLE
    /// =========================
    public fun add_auditor(
        admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        assert_admin(admin);
        grant_role(&mut roles.auditors, b"AUDITOR", addr);
    }

    public fun remove_auditor(
        admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        assert_admin(admin);
        revoke_role(&mut roles.auditors, b"AUDITOR", addr);
    }

    public fun is_auditor(
        roles: &Roles,
        addr: address
    ): bool {
        has_role(&roles.auditors, addr)
    }

    /// =========================
    /// TREASURY SIGNER ROLE
    /// =========================
    public fun add_treasury_signer(
        admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        assert_admin(admin);
        grant_role(&mut roles.treasury_signers, b"TREASURY_SIGNER", addr);
    }

    public fun remove_treasury_signer(
        admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        assert_admin(admin);
        revoke_role(&mut roles.treasury_signers, b"TREASURY_SIGNER", addr);
    }

    public fun is_treasury_signer(
        roles: &Roles,
        addr: address
    ): bool {
        has_role(&roles.treasury_signers, addr)
    }
}
