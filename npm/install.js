#!/usr/bin/env node
"use strict";

const https = require("https");
const { createWriteStream, chmodSync, mkdirSync, renameSync } = require("fs");
const { execFileSync } = require("child_process");
const path = require("path");
const os = require("os");

const RELEASES_API = "https://api.github.com/repos/BullpenFi/bullpen-cli-releases/releases";
const BIN_PATH = path.join(__dirname, "bin", "bullpen-bin");

function platform() {
  const { platform, arch } = process;
  if (platform === "darwin" && arch === "arm64") return "aarch64-apple-darwin";
  if (platform === "darwin" && arch === "x64") return "x86_64-apple-darwin";
  if (platform === "linux" && arch === "arm64") return "aarch64-unknown-linux-musl";
  if (platform === "linux" && arch === "x64") return "x86_64-unknown-linux-musl";
  throw new Error(`Unsupported platform: ${platform}/${arch}`);
}

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { "User-Agent": "bullpen-npm-installer" } }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) return resolve(get(res.headers.location));
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => resolve({ statusCode: res.statusCode, body: data }));
    }).on("error", reject);
  });
}

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = createWriteStream(dest);
    const fetch = (u) =>
      https.get(u, { headers: { "User-Agent": "bullpen-npm-installer" } }, (res) => {
        if (res.statusCode === 301 || res.statusCode === 302) return fetch(res.headers.location);
        if (res.statusCode !== 200) return reject(new Error(`HTTP ${res.statusCode} for ${u}`));
        res.pipe(file);
        file.on("finish", () => file.close(resolve));
      }).on("error", reject);
    fetch(url);
  });
}

async function resolveVersion() {
  const pinned = process.env.BULLPEN_VERSION;
  if (pinned && pinned !== "latest") return pinned;
  const { body } = await get(`${RELEASES_API}/latest`);
  const match = body.match(/"tag_name"\s*:\s*"v([^"]+)"/);
  if (!match) throw new Error("Could not determine latest bullpen version");
  return match[1];
}

async function main() {
  const version = await resolveVersion();
  const target = platform();
  const url = `https://github.com/BullpenFi/bullpen-cli-releases/releases/download/v${version}/bullpen-${version}-${target}.tar.gz`;
  const tmp = path.join(os.tmpdir(), `bullpen-install-${process.pid}`);
  const tarball = `${tmp}.tar.gz`;

  console.log(`Downloading bullpen v${version} for ${target}...`);
  const binDir = path.join(__dirname, "bin");
  mkdirSync(binDir, { recursive: true });
  await download(url, tarball);

  execFileSync("tar", ["-xzf", tarball, "-C", binDir, "bullpen"]);
  renameSync(path.join(binDir, "bullpen"), BIN_PATH);
  chmodSync(BIN_PATH, 0o755);

  try { require("fs").unlinkSync(tarball); } catch (_) {}
  console.log(`bullpen v${version} installed.`);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
