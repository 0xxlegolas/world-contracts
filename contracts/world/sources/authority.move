module world::authority {
    use sui::event;
    use world::world::GovernorCap;

    public struct AdminCap has key {
        id: UID,
    }

    public struct OwnerCap has key {
        id: UID,
    }

    public struct AdminCapMinted has copy, drop {
        admin_cap_id: object::ID,
        admin: address,
    }

    public struct OwnerCapMinted has copy, drop {
        owner_cap_id: object::ID,
        owner: address,
    }

    public fun mint_admin_cap(_: &GovernorCap, admin: address, ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };

        event::emit(AdminCapMinted {
            admin_cap_id: object::id(&admin_cap),
            admin: admin,
        });

        transfer::transfer(admin_cap, admin);
    }

    //TODO : add function to burn admin cap

    public fun mint_owner_cap(_: &GovernorCap, owner: address, ctx: &mut TxContext) {
        let owner_cap = OwnerCap {
            id: object::new(ctx),
        };

        event::emit(OwnerCapMinted {
            owner_cap_id: object::id(&owner_cap),
            owner: owner,
        });

        transfer::transfer(owner_cap, owner);
    }

    //TODO : add function to burn owner cap
}
