#[test_only]
module world::authority_tests;

use sui::test_scenario as ts;
use world::{authority::{Self, AdminCap}, world::{Self, GovernorCap}};

#[test]
fun mint_and_burn_admin_cap() {
    let _governor = @0xA;
    let _admin = @0xB;

    let mut ts = ts::begin(_governor);
    {
        world::init_for_testing(ts::ctx(&mut ts));
    };

    ts::next_tx(&mut ts, _governor);
    {
        let gov_cap = ts::take_from_sender<world::GovernorCap>(&ts);
        authority::mint_admin_cap(&gov_cap, _admin, ts::ctx(&mut ts));

        ts::return_to_sender(&ts, gov_cap);
    };

    ts::next_tx(&mut ts, _governor);
    {
        let gov_cap = ts::take_from_sender<world::GovernorCap>(&ts);
        let admin_cap = ts::take_from_address<AdminCap>(&ts, _admin);

        authority::burn_admin_cap(admin_cap, &gov_cap);

        ts::return_to_sender(&ts, gov_cap);
    };

    ts::end(ts);
}

#[test]
fun mint_owner_cap() {
    let _governor = @0xA;
    let _admin = @0xB;
    let _userA = @0xC;

    let mut ts = ts::begin(_governor);
    {
        world::init_for_testing(ts::ctx(&mut ts));
    };

    ts::next_tx(&mut ts, _governor);
    {
        let gov_cap = ts::take_from_sender<world::GovernorCap>(&ts);
        authority::mint_admin_cap(&gov_cap, _admin, ts::ctx(&mut ts));

        ts::return_to_sender(&ts, gov_cap);
    };

    ts::next_tx(&mut ts, _admin);
    {
        let admin_cap = ts::take_from_sender<authority::AdminCap>(&ts);

        let owner_cap = authority::mint_owner_cap(&admin_cap, ts::ctx(&mut ts));
        transfer::public_transfer(owner_cap, _userA);

        ts::return_to_sender(&ts, admin_cap);
    };

    ts::end(ts);
}
