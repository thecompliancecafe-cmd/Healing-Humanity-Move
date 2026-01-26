module healing_humanity::access_control {
    use std::vector;
    use sui::signer;

    struct Roles has key {
        admin: address,
        oracles: vector<address>,
        compliance_auth: vector<address>,
        treasury_signers: vector<address>,
        auditors: vector<address>,
    }

    public fun init_roles(
        admin: address,
        oracles: vector<address>,
        compliance_auth: vector<address>,
        treasury_signers: vector<address>,
        auditors: vector<address>
    ): Roles {
        Roles {
            admin,
            oracles,
            compliance_auth,
            treasury_signers,
            auditors,
        }
    }

    public fun is_admin(roles: &Roles, addr: address): bool {
        roles.admin == addr
    }

    public fun has_role(role_vec: &vector<address>, addr: address): bool {
        vector::contains(role_vec, addr)
    }
}
