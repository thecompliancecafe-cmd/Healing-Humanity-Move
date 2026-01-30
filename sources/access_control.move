module healing_humanity::access_control {
    use sui::table;
    use sui::transfer;

    /// Shared roles registry
    public struct Roles has key {
        id: object::UID,
        oracles: table::Table<address, bool>,
        compliance: table::Table<address, bool>,
        auditors: table::Table<address, bool>,
        treasury_signers: table::Table<address, bool>,
    }

    /// Admin capability
    public struct AdminCap has key {
        id: object::UID,
    }

    /// Initialize access control (called once at publish)
    fun init(ctx: &mut tx_context::TxContext) {
        let roles = Roles {
            id: object::new(ctx),
            oracles: table::new(ctx),
            compliance: table::new(ctx),
            auditors: table::new(ctx),
            treasury_signers: table::new(ctx),
        };

        let admin = AdminCap {
            id: object::new(ctx),
        };

        // Share roles registry
        transfer::share_object(roles);

        // Give admin cap to deployer
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    /// ---- ORACLES ----

    public fun add_oracle(
        _admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        if (!table::contains(&roles.oracles, addr)) {
            table::add(&mut roles.oracles, addr, true);
        }
    }

    public fun is_oracle(
        roles: &Roles,
        addr: address
    ): bool {
        table::contains(&roles.oracles, addr)
    }

    /// ---- COMPLIANCE ----

    public fun add_compliance(
        _admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        if (!table::contains(&roles.compliance, addr)) {
            table::add(&mut roles.compliance, addr, true);
        }
    }

    public fun is_compliance(
        roles: &Roles,
        addr: address
    ): bool {
        table::contains(&roles.compliance, addr)
    }

    /// ---- AUDITORS ----

    public fun add_auditor(
        _admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        if (!table::contains(&roles.auditors, addr)) {
            table::add(&mut roles.auditors, addr, true);
        }
    }

    public fun is_auditor(
        roles: &Roles,
        addr: address
    ): bool {
        table::contains(&roles.auditors, addr)
    }

    /// ---- TREASURY SIGNERS ----

    public fun add_treasury_signer(
        _admin: &AdminCap,
        roles: &mut Roles,
        addr: address
    ) {
        if (!table::contains(&roles.treasury_signers, addr)) {
            table::add(&mut roles.treasury_signers, addr, true);
        }
    }

    public fun is_treasury_signer(
        roles: &Roles,
        addr: address
    ): bool {
        table::contains(&roles.treasury_signers, addr)
    }
}
