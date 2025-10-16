#[test_only]

module world::character_tests;

use std::{string::utf8, unit_test::assert_eq};
use sui::test_scenario as ts;
use world::{
    authority::{Self, AdminCap, OwnerCap},
    character::{Self, Character},
    world::{Self, GovernorCap}
};

const GOVERNOR: address = @0xA;
const ADMIN: address = @0xB;
const USER_A: address = @0xC;
const USER_B: address = @0xD;

// Helper functions

fun setup_world(ts: &mut ts::Scenario) {
    ts::next_tx(ts, GOVERNOR);
    {
        world::init_for_testing(ts::ctx(ts));
    };

    ts::next_tx(ts, GOVERNOR);
    {
        let gov_cap = ts::take_from_sender<GovernorCap>(ts);
        authority::create_admin_cap(&gov_cap, ADMIN, ts::ctx(ts));
        ts::return_to_sender(ts, gov_cap);
    };
}

fun setup_owner_cap(ts: &mut ts::Scenario, owner: address, character_id: ID) {
    ts::next_tx(ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(ts);
        let owner_cap = authority::create_owner_cap(&admin_cap, character_id, ts::ctx(ts));
        authority::transfer_owner_cap(owner_cap, &admin_cap, owner);
        ts::return_to_sender(ts, admin_cap);
    };
}

fun setup_character(ts: &mut ts::Scenario, game_id: u32, tribe_id: u32, name: vector<u8>) {
    ts::next_tx(ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(ts);
        let character = character::create_character(
            &admin_cap,
            game_id,
            tribe_id,
            utf8(name),
            ts::ctx(ts),
        );
        character::share_character(character, &admin_cap);
        ts::return_to_sender(ts, admin_cap);
    };
}

#[test]
fun test_create_character() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);
    setup_character(&mut ts, 1, 100, b"test");

    ts::next_tx(&mut ts, ADMIN);
    {
        let character = ts::take_shared<Character>(&ts);

        assert_eq!(character::game_character_id(&character), 1);
        assert_eq!(character::tribe_id(&character), 100);
        assert_eq!(character::name(&character), utf8(b"test"));
        ts::return_shared(character);
    };

    ts.end();
}

#[test]
fun test_rename_character() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);
    setup_character(&mut ts, 1, 100, b"test");

    ts::next_tx(&mut ts, USER_A);
    {
        let character = ts::take_shared<Character>(&ts);
        let character_id = object::id(&character);
        ts::return_shared(character);

        setup_owner_cap(&mut ts, USER_A, character_id);
    };

    ts::next_tx(&mut ts, USER_A);
    {
        let owner_cap = ts::take_from_sender<OwnerCap>(&ts);
        let mut character = ts::take_shared<Character>(&ts);

        character::rename_character(&mut character, &owner_cap, utf8(b"new_name"));
        assert_eq!(character::name(&character), utf8(b"new_name"));

        ts::return_shared(character);
        ts::return_to_sender(&ts, owner_cap);
    };

    ts.end();
}

#[test]
fun test_update_tribe() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);
    setup_character(&mut ts, 1, 100, b"test");

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut character = ts::take_shared<Character>(&ts);

        character::update_tribe(&mut character, &admin_cap, 200);
        assert_eq!(character::tribe_id(&character), 200);

        ts::return_shared(character);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts.end();
}

#[test]
fun test_delete_character() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);
    setup_character(&mut ts, 1, 100, b"test");

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let character = ts::take_shared<Character>(&ts);

        character::delete_character(character, &admin_cap);

        ts::return_to_sender(&ts, admin_cap);
    };

    ts.end();
}

#[test]
#[expected_failure]
fun test_create_character_without_admin_cap() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    ts::next_tx(&mut ts, USER_A);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let character = character::create_character(
            &admin_cap,
            1,
            100,
            utf8(b"test"),
            ts::ctx(&mut ts),
        );
        character::share_character(character, &admin_cap);
        abort
    }
}

#[test]
#[expected_failure]
fun test_rename_character_without_owner_cap() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);
    setup_character(&mut ts, 1, 100, b"test");

    ts::next_tx(&mut ts, USER_B);
    {
        let owner_cap = ts::take_from_sender<OwnerCap>(&ts);
        let mut character = ts::take_shared<Character>(&ts);

        character::rename_character(&mut character, &owner_cap, utf8(b"new_name"));
        abort
    }
}
