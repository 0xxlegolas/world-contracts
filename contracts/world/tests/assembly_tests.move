#[test_only]

module world::assembly_tests;

use std::unit_test::assert_eq;
use sui::{clock, test_scenario as ts};
use world::{
    assembly::{Self, Assembly, AssemblyRegistry},
    authority::{Self, AdminCap, OwnerCap},
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
        world::init_for_testing(ts.ctx());
        assembly::init_for_testing(ts.ctx());
    };

    ts::next_tx(ts, GOVERNOR);
    {
        let gov_cap = ts::take_from_sender<GovernorCap>(ts);
        authority::create_admin_cap(&gov_cap, ADMIN, ts.ctx());
        ts::return_to_sender(ts, gov_cap);
    };
}

fun setup_owner_cap(ts: &mut ts::Scenario, owner: address, assembly_id: ID) {
    ts::next_tx(ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(ts);
        let owner_cap = authority::create_owner_cap(&admin_cap, assembly_id, ts.ctx());
        authority::transfer_owner_cap(owner_cap, &admin_cap, owner);
        ts::return_to_sender(ts, admin_cap);
    }
}

// Different assembly types
public struct PlainAssembly has key {
    id: UID,
}

// Simple inventory item with store ability
#[allow(unused_field)]
public struct InventoryItem has drop, store {
    item_type_id: u64,
    quantity: u64,
}

// Inventory can store items using a vector
#[allow(unused_field)]
public struct Inventory has store {
    capacity: u64,
    items: vector<InventoryItem>,
}

#[allow(unused_field)]
public struct StorageUnit has key {
    id: UID,
    inventory_capacity: u64,
    inventory: Inventory,
}

#[test]
fun create_assembly_registry() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    ts::next_tx(&mut ts, GOVERNOR);
    {
        let registry = ts::take_shared<AssemblyRegistry>(&ts);
        // Registry should exist and be shared
        ts::return_shared(registry);
    };

    ts::end(ts);
}

#[test]
fun create_plain_assembly() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            100u64,
            50u64,
            ts.ctx(),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts::next_tx(&mut ts, ADMIN);
    {
        let assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);
        assert_eq!(assembly::type_id(&assembly), 1u64);
        assert_eq!(assembly::item_id(&assembly), 100u64);
        assert_eq!(assembly::volume(&assembly), 50u64);
        assert_eq!(assembly::status_to_u8(&assembly), 0);
        ts::return_shared(assembly);
    };

    ts::end(ts);
}

#[test]
fun create_storage_unit_assembly() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<StorageUnit>(
            &mut registry,
            &admin_cap,
            2u64,
            200u64,
            1000u64,
            ts::ctx(&mut ts),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts::next_tx(&mut ts, ADMIN);
    {
        let assembly = ts::take_shared<Assembly<StorageUnit>>(&ts);
        ts::return_shared(assembly);
    };

    ts.end();
}

#[test]
fun anchor_assembly() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    // Create assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            100u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    // Anchor assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::anchor_assembly(&mut assembly, &admin_cap);
        assert_eq!(assembly::status_to_u8(&assembly), 1);

        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts.end();
}

#[test]
fun unanchor_assembly() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    // Create and anchor assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            100u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::anchor_assembly(&mut assembly, &admin_cap);

        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    // Unanchor assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::unanchor_assembly(&mut assembly, &admin_cap);
        assert_eq!(assembly::status_to_u8(&assembly), 0);

        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts.end();
}

#[test]
fun online_assembly() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    // Create and anchor assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            100u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::anchor_assembly(&mut assembly, &admin_cap);

        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    // Online assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);
        let clock = clock::create_for_testing(ts::ctx(&mut ts));

        assembly::online_assembly(&mut assembly, &admin_cap, &clock);
        assert_eq!(assembly::status_to_u8(&assembly), 2);

        clock::destroy_for_testing(clock);
        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts.end();
}

#[test]
fun offline_assembly() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    let assembly_id: ID;

    // Create, anchor, and online assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            100u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly_id = object::id(&assembly);
        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::anchor_assembly(&mut assembly, &admin_cap);

        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);
        let clock = clock::create_for_testing(ts::ctx(&mut ts));

        assembly::online_assembly(&mut assembly, &admin_cap, &clock);

        clock::destroy_for_testing(clock);
        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    // Setup owner cap for USER_A
    setup_owner_cap(&mut ts, USER_A, assembly_id);

    // Offline assembly with owner cap
    ts::next_tx(&mut ts, USER_A);
    {
        let owner_cap = ts::take_from_sender<OwnerCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::offline_assembly(&mut assembly, &owner_cap);
        assert_eq!(assembly::status_to_u8(&assembly), 1);

        ts::return_shared(assembly);
        ts::return_to_sender(&ts, owner_cap);
    };

    ts.end();
}

#[test]
fun destroy_assembly() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    // Create assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            100u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    // Destroy assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::destroy_assembly(&mut assembly, &admin_cap);

        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts.end();
}

#[test]
#[expected_failure(abort_code = assembly::ETypeIdEmpty)]
fun anchor_assembly_invalid_type_id() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    // Try to create assembly with game_type_id = 0 (invalid)
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            0u64,
            100u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };
    abort
}

#[test]
#[expected_failure(abort_code = assembly::EItemIdEmpty)]
fun unanchor_assembly_invalid_item_id() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    // Try to create assembly with game_item_id = 0 (invalid)
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            0u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    abort
}

#[test]
#[expected_failure(abort_code = assembly::EAssemblyInvalidState)]
fun online_assembly_invalid_state() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    // Create assembly but don't anchor it
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            100u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    // Try to online without anchoring first (should fail)
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);
        let clock = clock::create_for_testing(ts::ctx(&mut ts));

        assembly::online_assembly(&mut assembly, &admin_cap, &clock);

        clock::destroy_for_testing(clock);
        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    abort
}

#[test]
#[expected_failure(abort_code = assembly::EAssemblyAccessNotAuthorized)]
fun offline_assembly_unauthorized() {
    let mut ts = ts::begin(GOVERNOR);
    setup_world(&mut ts);

    let assembly_id: ID;

    // Create, anchor, and online assembly
    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut registry = ts::take_shared<AssemblyRegistry>(&ts);

        let assembly = assembly::create_assembly<PlainAssembly>(
            &mut registry,
            &admin_cap,
            1u64,
            100u64,
            50u64,
            ts::ctx(&mut ts),
        );

        assembly_id = object::id(&assembly);
        assembly::share_assembly(assembly, &admin_cap);
        ts::return_shared(registry);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::anchor_assembly(&mut assembly, &admin_cap);

        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    ts::next_tx(&mut ts, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&ts);
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);
        let clock = clock::create_for_testing(ts::ctx(&mut ts));

        assembly::online_assembly(&mut assembly, &admin_cap, &clock);

        clock::destroy_for_testing(clock);
        ts::return_shared(assembly);
        ts::return_to_sender(&ts, admin_cap);
    };

    // Setup owner cap for USER_A (not USER_B)
    setup_owner_cap(&mut ts, USER_A, assembly_id);

    // Try to offline assembly with USER_B (unauthorized, should fail)
    ts::next_tx(&mut ts, USER_B);
    {
        // Create an owner cap for a different object (unauthorized)
        let admin_cap = ts::take_from_address<AdminCap>(&ts, ADMIN);
        let wrong_owner_cap = authority::create_owner_cap(
            &admin_cap,
            object::id_from_address(@0x9999), // Wrong object ID
            ts::ctx(&mut ts),
        );
        let mut assembly = ts::take_shared<Assembly<PlainAssembly>>(&ts);

        assembly::offline_assembly(&mut assembly, &wrong_owner_cap);

        authority::delete_owner_cap(wrong_owner_cap, &admin_cap);
        ts::return_shared(assembly);
        ts::return_to_address(ADMIN, admin_cap);
    };

    abort
}
