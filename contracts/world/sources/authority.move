module world::authority {
    use sui::event;
    use world::world::GovernorCap;

    public struct AdminCap has key, store {
        id: UID,
        admin: address,
    }

    public struct OwnerCap has key, store {
        id: UID,
    }

    public struct AdminCapMinted has copy, drop {
        admin_cap_id: object::ID,
        admin: address,
    }

    public fun mint_admin_cap(_: &GovernorCap, admin: address, ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
            admin: admin,
        };
        event::emit(AdminCapMinted {
            admin_cap_id: object::id(&admin_cap),
            admin: admin,
        });

        transfer::transfer(admin_cap, admin);
    }

    public fun burn_admin_cap(_: &GovernorCap, admin_cap: AdminCap) {
        let AdminCap { id, .. } = admin_cap;
        id.delete();
    }

    public fun mint_owner_cap(_: &AdminCap, ctx: &mut TxContext): OwnerCap {
        OwnerCap {
            id: object::new(ctx),
        }
    }

    //TODO : add function to burn owner cap
}
