module world::world;

use sui::event;

public struct GovernorCap has key {
    id: UID,
    governor: address,
}

public struct WorldCreatedEvent has copy, drop {
    governor_cap_id: ID,
    governor: address,
}

// TODO: mint initial supply of eve tokens
fun init(ctx: &mut TxContext) {
    let gov_cap = GovernorCap {
        id: object::new(ctx),
        governor: ctx.sender(),
    };

    event::emit(WorldCreatedEvent {
        governor_cap_id: object::id(&gov_cap),
        governor: ctx.sender(),
    });

    transfer::transfer(gov_cap, ctx.sender());
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}
