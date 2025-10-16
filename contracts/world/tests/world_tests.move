#[test_only]
module world::world_tests;

use sui::test_scenario;
use world::world;

#[test]
fun creates_governor_cap() {
    let governor = @0xA;
    let mut scenario = test_scenario::begin(governor);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        world::init_for_testing(ctx);
    };

    test_scenario::next_tx(&mut scenario, governor);
    {
        let gov_cap = test_scenario::take_from_sender<world::GovernorCap>(&scenario);

        test_scenario::return_to_sender(&scenario, gov_cap);
    };
    test_scenario::end(scenario);
}
