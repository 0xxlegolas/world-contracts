module world::authority;

use sui::event;
use world::world::GovernorCap;

public struct AdminCap has key {
    id: UID,
    admin: address,
}

// TODO: Rename this to Title ? KeyCard ?
public struct OwnerCap has key {
    id: UID,
}

public struct AdminCapCreatedEvent has copy, drop {
    admin_cap_id: ID,
    admin: address,
}

public fun create_admin_cap(_: &GovernorCap, admin: address, ctx: &mut TxContext) {
    let admin_cap = AdminCap {
        id: object::new(ctx),
        admin: admin,
    };
    event::emit(AdminCapCreatedEvent {
        admin_cap_id: object::id(&admin_cap),
        admin: admin,
    });

    //Its intentionally in the same function for simplicity, this can be split into 2 functions for composability
    transfer::transfer(admin_cap, admin);
}

public fun delete_admin_cap(admin_cap: AdminCap, _: &GovernorCap) {
    let AdminCap { id, .. } = admin_cap;
    id.delete();
}

public fun create_owner_cap(_: &AdminCap, ctx: &mut TxContext): OwnerCap {
    OwnerCap {
        id: object::new(ctx),
    }
}

public fun transfer_owner_cap(owner_cap: OwnerCap, _: &AdminCap, owner: address) {
    transfer::transfer(owner_cap, owner);
}

// Ideally only the owner can delete the owner cap
public fun delete_owner_cap(owner_cap: OwnerCap, _: &AdminCap) {
    let OwnerCap { id, .. } = owner_cap;
    id.delete();
}
