module world::character;

use std::string::String;
use sui::event;
use world::authority::{OwnerCap, AdminCap, mint_owner_cap};

public struct Character has key, store {
    id: UID,
    game_character_id: u64,
    tribe_id: u64,
    name: String,
    owner_cap: ID,
}

public struct CharacterCreated has copy, drop {
    character_id: ID,
    game_character_id: u64,
    tribe_id: u64,
    name: String,
    character_address: address,
    owner_cap: ID,
}

// Create a character and mint a owner capability to the character address
public fun create_character(
    admin_cap: &AdminCap,
    character_address: address,
    game_character_id: u64,
    tribe_id: u64,
    name: String,
    ctx: &mut TxContext,
) {
    //Mint a owner capability to the character address
    let owner_cap = mint_owner_cap(admin_cap, ctx);

    let character = Character {
        id: object::new(ctx), // TODO: use deterministic id generation using the game id
        game_character_id: game_character_id,
        tribe_id: tribe_id,
        name: name,
        owner_cap: object::id(&owner_cap),
    };
    event::emit(CharacterCreated {
        character_id: object::id(&character),
        game_character_id: game_character_id,
        tribe_id: tribe_id,
        name: name,
        character_address: character_address,
        owner_cap: object::id(&owner_cap),
    });
    transfer::public_transfer(owner_cap, character_address);
    transfer::share_object(character);
}

// renames a character using ownerCap

// delete a character using adminCap

// update a character tribe using both ownerCap and adminCap ? or just adminCap ?
