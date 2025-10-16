/// This module manages character creation and lifecycle with capability-based access control.
///
/// Game characters have flexible ownership and access control beyond simple wallet-based ownership.
/// Characters are shared objects and mutable by admin and the character owner using capabilities.

module world::character;

use std::string::String;
use sui::event;
use world::authority::{Self, OwnerCap, AdminCap};

#[error]
const ECharacterNotAuthorized: u64 = 0;

// Events
public struct CharacterCreatedEvent has copy, drop {
    character_id: ID,
    game_character_id: u32,
    tribe_id: u32,
    name: String,
}

public struct Character has key {
    id: UID,
    game_character_id: u32,
    tribe_id: u32,
    name: String,
}

public fun create_character(
    _: &AdminCap,
    game_character_id: u32,
    tribe_id: u32,
    name: String,
    ctx: &mut TxContext,
): Character {
    // TODO: Should we do empty field checks ?

    // TODO: use deterministic id generation using the game id
    // If we use this, this will fail if we try to create the same ID twice, Cannot create same character twice
    let character = Character {
        id: object::new(ctx),
        game_character_id: game_character_id,
        tribe_id: tribe_id,
        name: name,
    };
    event::emit(CharacterCreatedEvent {
        character_id: object::id(&character),
        game_character_id: game_character_id,
        tribe_id: tribe_id,
        name: name,
    });
    character
}

public fun share_character(character: Character, _: &AdminCap) {
    transfer::share_object(character);
}

public fun rename_character(character: &mut Character, owner_cap: &OwnerCap, name: String) {
    assert!(authority::is_authorized(owner_cap, object::id(character)), ECharacterNotAuthorized);
    character.name = name;
}

public fun update_tribe(character: &mut Character, _: &AdminCap, tribe_id: u32) {
    character.tribe_id = tribe_id;
}

public fun delete_character(character: Character, _: &AdminCap) {
    let Character { id, .. } = character;
    id.delete();
}

#[test_only]
public fun game_character_id(character: &Character): u32 {
    character.game_character_id
}

#[test_only]
public fun tribe_id(character: &Character): u32 {
    character.tribe_id
}

#[test_only]
public fun name(character: &Character): String {
    character.name
}
