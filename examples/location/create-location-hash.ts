import "dotenv/config";
import { poseidon5 } from "poseidon-lite";
import { toHex } from "../utils/helper";

function createLocationHash(
    solarSystemId: number,
    x: string,
    y: string,
    z: string,
    serverSalt: bigint
): string {
    const systemIdBigInt = BigInt(solarSystemId);
    const xBigInt = BigInt(x);
    const yBigInt = BigInt(y);
    const zBigInt = BigInt(z);

    const hash = poseidon5([systemIdBigInt, xBigInt, yBigInt, zBigInt, serverSalt]);

    // Convert hash to 32-byte buffer (little-endian to match Sui)
    const buffer = new Uint8Array(32);
    let value = BigInt(hash);
    for (let i = 0; i < 32; i++) {
        buffer[i] = Number(value & 0xffn);
        value = value >> 8n;
    }

    return toHex(buffer);
}

async function main() {
    console.log("=== Location Hash Creation Example ===");
    console.log("Compatible with Sui's poseidon_bn254 native function\n");

    // Hardcoded solar system configuration
    const SOLAR_SYSTEM_ID = 30000005;
    const LOCATION_X = "12584731992391680";
    const LOCATION_Y = "-4253488649338880";
    const LOCATION_Z = "75645608342616800000";

    const serverSalt = process.env.SERVER_SALT
        ? BigInt(process.env.SERVER_SALT)
        : 123456789012345678901234567890n;

    console.log("Server Configuration:");
    console.log(`  Server Salt: ${serverSalt.toString()}`);
    console.log();

    console.log("=== Generating Location Hash ===");
    const locationHash = createLocationHash(
        SOLAR_SYSTEM_ID,
        LOCATION_X,
        LOCATION_Y,
        LOCATION_Z,
        serverSalt
    );

    console.log(`Location Hash: ${locationHash}`);
    console.log(`Hash Length: ${(locationHash.length - 2) / 2} bytes`);
    console.log();

    console.log("=== Usage in Sui Smart Contracts ===");
    console.log(`  Location { structure_id: <ID>, location_hash: ${locationHash} }`);
    console.log();
    console.log("=== Example: Multiple Structures ===");
    const structures = [
        {
            name: "Gate Alpha",
            systemId: 30000005,
            x: "12584731992391680",
            y: "-4253488649338880",
            z: "75645608342616800000",
        },
        {
            name: "Storage Beta",
            systemId: 30000005,
            x: "12584731992391681",
            y: "-4253488649338880",
            z: "75645608342616800000",
        },
        {
            name: "Rift Gamma",
            systemId: 30000006,
            x: "12584731992391680",
            y: "-4253488649338881",
            z: "75645608342616800000",
        },
    ];

    for (const structure of structures) {
        const hash = createLocationHash(
            structure.systemId,
            structure.x,
            structure.y,
            structure.z,
            serverSalt
        );
        console.log(`  ${structure.name} (System ${structure.systemId}): ${hash}`);
    }
}

main().catch((error) => {
    console.error("\n=== Error ===");
    console.error("Error:", error instanceof Error ? error.message : error);
    if (error instanceof Error && error.stack) {
        console.error("Stack:", error.stack);
    }
    process.exit(1);
});
