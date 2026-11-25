import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, readdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const DEFAULT_ROOT = fileURLToPath(new URL("../", import.meta.url));
const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let k = 0; k < 8; k++) c = (c & 1) !== 0 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[i] = c >>> 0;
  }
  return table;
})();

export const EXCLUDED_PATTERNS = [
  "Hidden files and directories (.*)",
  "Symbolic links",
  "project.godot",
  "*_scene.tscn",
  "*.sh",
  "*.md"
];

export const SHARED_MOD_SYNC_SPEC = [
  {
    source: "mods/_shared/minigame-hub/override_game.gd",
    targets: [
      "mods/bubble-blitz/override_game.gd",
      "mods/mpm-core/override_game.gd",
      "mods/roller-carnival/override_game.gd",
      "mods/spike-ring/override_game.gd"
    ]
  },
  {
    source: "mods/_shared/minigame-hub/override_local_game.gd",
    targets: [
      "mods/bubble-blitz/override_local_game.gd",
      "mods/mpm-core/override_local_game.gd",
      "mods/roller-carnival/override_local_game.gd",
      "mods/spike-ring/override_local_game.gd"
    ]
  },
  {
    source: "mods/_shared/minigame-hub/override_picker.gd",
    targets: [
      "mods/bubble-blitz/override_picker.gd",
      "mods/mpm-core/override_picker.gd",
      "mods/roller-carnival/override_picker.gd",
      "mods/spike-ring/override_picker.gd"
    ]
  },
  {
    source: "mods/_shared/minigame-hub/override_playlist.gd",
    targets: [
      "mods/bubble-blitz/override_playlist.gd",
      "mods/mpm-core/override_playlist.gd",
      "mods/roller-carnival/override_playlist.gd",
      "mods/spike-ring/override_playlist.gd"
    ]
  },
  {
    source: "mods/_shared/team-support/team_support.gd",
    targets: [
      "mods/bomb-cart/team_support.gd",
      "mods/bubble-blitz/team_support.gd",
      "mods/core-heist/team_support.gd",
      "mods/roller-carnival/team_support.gd",
      "mods/spike-ring/team_support.gd"
    ]
  }
];

export function isSkippedEntry(name) {
  return (
    name.startsWith(".") ||
    name === "project.godot" ||
    name.endsWith(".sh") ||
    name.endsWith(".md") ||
    name.endsWith("_scene.tscn")
  );
}

function crc32(bytes) {
  let c = 0xffffffff;
  for (let i = 0; i < bytes.length; i++) {
    c = CRC_TABLE[(c ^ bytes[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

function toLf(bytes) {
  // Windows checkouts can be CRLF; normalize text payloads so every platform packs identical bytes.
  if (bytes.includes(0)) return bytes;
  let count = 0;
  for (let i = 0; i < bytes.length - 1; i++) {
    if (bytes[i] === 13 && bytes[i + 1] === 10) count++;
  }
  if (count === 0) return bytes;
  const out = Buffer.allocUnsafe(bytes.length - count);
  let j = 0;
  for (let i = 0; i < bytes.length; i++) {
    if (bytes[i] === 13 && bytes[i + 1] === 10) continue;
    out[j++] = bytes[i];
  }
  return out;
}

async function collectRuntimeFiles(baseDir, currentDir = baseDir) {
  const entries = await readdir(currentDir, { withFileTypes: true });
  entries.sort((a, b) => a.name.localeCompare(b.name, "en"));
  const found = [];
  for (const entry of entries) {
    if (entry.isSymbolicLink() || isSkippedEntry(entry.name)) continue;
    const abs = path.join(currentDir, entry.name);
    if (entry.isDirectory()) {
      found.push(...(await collectRuntimeFiles(baseDir, abs)));
    } else if (entry.isFile()) {
      const rel = path.relative(baseDir, abs).split(path.sep).join("/");
      found.push({ rel, abs });
    }
  }
  return found.sort((a, b) => a.rel.localeCompare(b.rel, "en"));
}

function buildDeterministicZip(entries) {
  const localParts = [];
  const centralParts = [];
  let offset = 0;

  for (const { rel, data } of entries) {
    const nameBytes = Buffer.from(rel, "utf8");
    const crc = crc32(data);
    const size = data.length;

    const lfh = Buffer.alloc(30 + nameBytes.length);
    lfh.writeUInt32LE(0x04034b50, 0);
    lfh.writeUInt16LE(20, 4);
    lfh.writeUInt16LE(0x0000, 6);
    lfh.writeUInt16LE(0, 8);
    lfh.writeUInt16LE(0, 10);
    lfh.writeUInt16LE(0x0021, 12);
    lfh.writeUInt32LE(crc, 14);
    lfh.writeUInt32LE(size, 18);
    lfh.writeUInt32LE(size, 22);
    lfh.writeUInt16LE(nameBytes.length, 26);
    lfh.writeUInt16LE(0, 28);
    nameBytes.copy(lfh, 30);

    const cdfh = Buffer.alloc(46 + nameBytes.length);
    cdfh.writeUInt32LE(0x02014b50, 0);
    cdfh.writeUInt16LE(0x0314, 4);
    cdfh.writeUInt16LE(20, 6);
    cdfh.writeUInt16LE(0x0000, 8);
    cdfh.writeUInt16LE(0, 10);
    cdfh.writeUInt16LE(0, 12);
    cdfh.writeUInt16LE(0x0021, 14);
    cdfh.writeUInt32LE(crc, 16);
    cdfh.writeUInt32LE(size, 20);
    cdfh.writeUInt32LE(size, 24);
    cdfh.writeUInt16LE(nameBytes.length, 28);
    cdfh.writeUInt16LE(0, 30);
    cdfh.writeUInt16LE(0, 32);
    cdfh.writeUInt16LE(0, 34);
    cdfh.writeUInt16LE(0, 36);
    cdfh.writeUInt32LE(0x81a40000, 38);
    cdfh.writeUInt32LE(offset, 42);
    nameBytes.copy(cdfh, 46);

    localParts.push(lfh, data);
    centralParts.push(cdfh);
    offset += lfh.length + size;
  }

  const centralDir = Buffer.concat(centralParts);
  const eocd = Buffer.alloc(22);
  eocd.writeUInt32LE(0x06054b50, 0);
  eocd.writeUInt16LE(0, 4);
  eocd.writeUInt16LE(0, 6);
  eocd.writeUInt16LE(entries.length, 8);
  eocd.writeUInt16LE(entries.length, 10);
  eocd.writeUInt32LE(centralDir.length, 12);
  eocd.writeUInt32LE(offset, 16);
  eocd.writeUInt16LE(0, 20);

  return Buffer.concat([...localParts, centralDir, eocd]);
}

export async function listFirstPartyMods(rootDir = DEFAULT_ROOT) {
  const modsDir = path.join(rootDir, "mods");
  const dirents = await readdir(modsDir, { withFileTypes: true });
  dirents.sort((a, b) => a.name.localeCompare(b.name, "en"));
  const ids = [];
  for (const dirent of dirents) {
    if (!dirent.isDirectory() || dirent.name.startsWith(".")) continue;
    try {
      await readFile(path.join(modsDir, dirent.name, "mod.json"), "utf8");
      ids.push(dirent.name);
    } catch {
      // Ignore directories without mod.json.
    }
  }
  return ids;
}

export async function packMod(modId, rootDir = DEFAULT_ROOT) {
  assert.match(modId, /^[a-z0-9-]+$/);
  const modDir = path.join(rootDir, "mods", modId);
  const manifest = JSON.parse(await readFile(path.join(modDir, "mod.json"), "utf8"));
  assert.equal(manifest.id, modId, `mod.json id mismatch for ${modId}`);
  assert.equal(typeof manifest.version, "string");
  assert.ok(manifest.version.length > 0, `mod.json version empty for ${modId}`);

  const collected = await collectRuntimeFiles(modDir);
  assert.ok(collected.length > 0, `no runtime files found for ${modId}`);
  const entries = await Promise.all(
    collected.map(async ({ rel, abs }) => ({
      rel,
      data: toLf(await readFile(abs))
    }))
  );
  const bytes = buildDeterministicZip(entries);
  const sha256 = createHash("sha256").update(bytes).digest("hex");

  return {
    id: modId,
    version: manifest.version,
    filename: `${modId}-${manifest.version}.zip`,
    size: bytes.length,
    sha256,
    files: entries.map(entry => entry.rel),
    bytes
  };
}

export async function syncSharedModFiles(rootDir = DEFAULT_ROOT) {
  const updated = [];
  for (const { source, targets } of SHARED_MOD_SYNC_SPEC) {
    const srcBytes = toLf(await readFile(path.join(rootDir, source)));
    for (const relTarget of targets) {
      const targetPath = path.join(rootDir, relTarget);
      let curBytes = null;
      try {
        curBytes = toLf(await readFile(targetPath));
      } catch {
        curBytes = null;
      }
      if (!curBytes || !srcBytes.equals(curBytes)) {
        await writeFile(targetPath, srcBytes);
        updated.push(relTarget);
      }
    }
  }
  return updated;
}

async function verifyCatalogParity(packed, rootDir) {
  const catalog = JSON.parse(await readFile(path.join(rootDir, "catalog/mods.json"), "utf8"));
  for (const item of packed) {
    const entry = catalog.mods.find(mod => mod.id === item.id);
    assert.ok(entry, `catalog/mods.json is missing mod ${item.id}`);
    assert.equal(entry.version, `v${item.version}`, `${item.id}: version mismatch with catalog`);
    assert.ok(entry.package, `${item.id}: expected package metadata in catalog/mods.json`);
    assert.equal(entry.package.filename, item.filename, `${item.id}: package filename mismatch`);
    assert.equal(entry.package.size, item.size, `${item.id}: package size mismatch`);
    assert.equal(entry.package.sha256, item.sha256, `${item.id}: package sha256 mismatch`);
    assert.deepEqual(
      [...entry.adapter.requiredFiles].sort(),
      [...item.files].sort(),
      `${item.id}: adapter.requiredFiles must match packed runtime files`
    );
  }
}

async function main() {
  const args = process.argv.slice(2);
  let all = false;
  let verifyCatalog = false;
  let syncShared = false;
  let outDir = "";
  const modIds = [];

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--all") all = true;
    else if (arg === "--verify-catalog") verifyCatalog = true;
    else if (arg === "--sync-shared") syncShared = true;
    else if (arg === "--out") {
      outDir = args[++i] || "";
      assert.ok(outDir, "--out requires a directory path");
    } else if (!arg.startsWith("-")) {
      modIds.push(arg);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (syncShared) {
    const updated = await syncSharedModFiles(DEFAULT_ROOT);
    if (!all && modIds.length === 0) {
      process.stdout.write(JSON.stringify({ synced: updated }, null, 2) + "\n");
      return;
    }
  }

  const targets = all ? await listFirstPartyMods(DEFAULT_ROOT) : modIds;
  assert.ok(targets.length > 0, "Specify --all or one or more mod IDs");

  const packed = [];
  for (const modId of targets) packed.push(await packMod(modId, DEFAULT_ROOT));

  if (verifyCatalog) await verifyCatalogParity(packed, DEFAULT_ROOT);

  if (outDir) {
    await mkdir(outDir, { recursive: true });
    for (const item of packed) {
      const dest = path.join(outDir, `${item.sha256}.zip`);
      await writeFile(dest, item.bytes);
      const written = await readFile(dest);
      assert.equal(written.length, item.size);
      assert.equal(createHash("sha256").update(written).digest("hex"), item.sha256);
    }
  }

  const summary = packed.map(({ bytes: _, ...meta }) => meta);
  process.stdout.write(JSON.stringify(summary.length === 1 && !all ? summary[0] : summary, null, 2) + "\n");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
