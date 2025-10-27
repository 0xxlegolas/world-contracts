/// This module manages the lifecycle of a assembly in the world.
///
/// Basic Assembly operations are: Anchor, Unanchor, Online, Offline and Destroy assembly
/// Assembly is a shared object and mutable by admin and the assembly owner using capabilities.

module world::assembly;

use sui::{clock::Clock, derived_object, event};
use world::authority::{Self, OwnerCap, AdminCap};

#[error(code = 0)]
const ETypeIdEmpty: vector<u8> = b"Type ID is empty";

#[error(code = 1)]
const EItemIdEmpty: vector<u8> = b"Item ID is empty";

#[error(code = 2)]
const EAssemblyAccessNotAuthorized: vector<u8> = b"Assembly access not authorized";

#[error(code = 3)]
const EAssemblyInvalidState: vector<u8> = b"Assembly is in an invalid state";

public enum AssemblyStatus has copy, drop, store {
    UNANCHORED,
    ANCHORED,
    ONLINE { online_at: u64 }, // Useful for fuel/energy consumption calculations
    DESTROYED,
}

public struct AssemblyRegistry has key {
    id: UID,
}

public struct Assembly<phantom T> has key {
    id: UID,
    type_id: u64,
    item_id: u64,
    volume: u64,
    status: AssemblyStatus,
}

public struct AssemblyCreatedEvent has copy, drop {
    assembly_id: ID,
    type_id: u64,
    item_id: u64,
    volume: u64,
    status: AssemblyStatus,
}

fun init(ctx: &mut TxContext) {
    transfer::share_object(AssemblyRegistry {
        id: object::new(ctx),
    });
}

public fun create_assembly<T>(
    registry: &mut AssemblyRegistry,
    _: &AdminCap,
    type_id: u64,
    item_id: u64,
    volume: u64,
    _: &mut TxContext,
): Assembly<T> {
    assert!(type_id != 0, ETypeIdEmpty);
    assert!(item_id != 0, EItemIdEmpty);
    let assembly = Assembly {
        id: derived_object::claim(&mut registry.id, item_id),
        type_id,
        item_id,
        volume,
        status: AssemblyStatus::UNANCHORED,
    };
    event::emit(AssemblyCreatedEvent {
        assembly_id: object::id(&assembly),
        type_id: assembly.type_id,
        item_id: assembly.item_id,
        volume: assembly.volume,
        status: assembly.status,
    });
    assembly
}

public fun share_assembly<T>(assembly: Assembly<T>, _: &AdminCap) {
    transfer::share_object(assembly);
}

public fun anchor_assembly<T>(assembly: &mut Assembly<T>, _: &AdminCap) {
    assert!(assembly.status == AssemblyStatus::UNANCHORED, EAssemblyInvalidState);
    assembly.status = AssemblyStatus::ANCHORED;
}

public fun unanchor_assembly<T>(assembly: &mut Assembly<T>, _: &AdminCap) {
    assert!(
        assembly.status == AssemblyStatus::ANCHORED || is_online(&assembly.status),
        EAssemblyInvalidState,
    );
    assembly.status = AssemblyStatus::UNANCHORED;
}

public fun online_assembly<T>(assembly: &mut Assembly<T>, _: &AdminCap, clock: &Clock) {
    assert!(assembly.status == AssemblyStatus::ANCHORED, EAssemblyInvalidState);
    assembly.status = AssemblyStatus::ONLINE { online_at: clock.timestamp_ms() };
}

public fun offline_assembly<T>(assembly: &mut Assembly<T>, owner_cap: &OwnerCap) {
    assert!(
        authority::is_authorized(owner_cap, object::id(assembly)),
        EAssemblyAccessNotAuthorized,
    );
    assert!(is_online(&assembly.status), EAssemblyInvalidState);
    assembly.status = AssemblyStatus::ANCHORED;
}

public fun destroy_assembly<T>(assembly: &mut Assembly<T>, _: &AdminCap) {
    assert!(
        assembly.status == AssemblyStatus::UNANCHORED || assembly.status == AssemblyStatus::ANCHORED,
        EAssemblyInvalidState,
    );
    assembly.status = AssemblyStatus::DESTROYED;
}

public fun is_online(status: &AssemblyStatus): bool {
    match (*status) {
        AssemblyStatus::ONLINE { online_at: _ } => true,
        _ => false,
    }
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}

#[test_only]
public fun type_id<T>(assembly: &Assembly<T>): u64 {
    assembly.type_id
}

#[test_only]
public fun item_id<T>(assembly: &Assembly<T>): u64 {
    assembly.item_id
}

#[test_only]
public fun volume<T>(assembly: &Assembly<T>): u64 {
    assembly.volume
}

#[test_only]
public fun status<T>(assembly: &Assembly<T>): &AssemblyStatus {
    &assembly.status
}

#[test_only]
public fun status_to_u8<T>(assembly: &Assembly<T>): u8 {
    match (assembly.status) {
        AssemblyStatus::UNANCHORED => 0,
        AssemblyStatus::ANCHORED => 1,
        AssemblyStatus::ONLINE { online_at: _ } => 2,
        AssemblyStatus::DESTROYED => 3,
    }
}
