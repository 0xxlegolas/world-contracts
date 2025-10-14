module world::world {
    use sui::event;

    public struct GovernorCap has key {
        id: UID,
        governor: address,
    }

    public struct WorldCreated has copy, drop {
        governor_cap_id: object::ID,
        owner: address,
    }

    // On init, create a Governor Cap and send it to the creator of the contract
    // TODO: mint a initial supply of eve tokens
    fun init(ctx: &mut TxContext) {
        let gov_cap = GovernorCap {
            id: object::new(ctx),
            governor: ctx.sender(),
        };

        let id = object::id(&gov_cap);

        event::emit(WorldCreated {
            governor_cap_id: id,
            owner: ctx.sender(),
        });

        transfer::transfer(gov_cap, ctx.sender());
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
