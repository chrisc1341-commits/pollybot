#!/usr/bin/env node
"use strict";

const https = require("https");
const { createWriteStream, chmodSync, mkdirSync } = require("fs");
const { execFileSync } = require("child_process");
const path = require("path");
const os = require("os");

const VERSION = "0.1.83";
const BIN_PATH = path.join(__dirname, "bin", "bullpen-bin");

function platform() {
  const { platform, arch } = process;
  if (platform === "darwin" && arch === "arm64") return "aarch64-apple-darwin";
  if (platform === "darwin" && arch === "x64") return "x86_64-apple-darwin";
  if (platform === "linux" && arch === "arm64") return "aarch64-unknown-linux-musl";
  if (platform === "linux" && arch === "x64") return "x86_64-unknown-linux-musl";
  throw new Error(`Unsupported platform: ${platform}/${arch}`);
}

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = createWriteStream(dest);
    const get = (u) =>
      https.get(u, (res) => {
        if (res.statusCode === 301 || res.statusCode === 302) {
          return get(res.headers.location);
        }
        if (res.statusCode !== 200) {
          return reject(new Error(`HTTP ${res.statusCode} for ${u}`));
        }
        res.pipe(file);
        file.on("finish", () => file.close(resolve));
      }).on("error", reject);
    get(url);
  });
}

async function main() {
  const target = platform();
  const url = `https://github.com/BullpenFi/bullpen-cli-releases/releases/download/v${VERSION}/bullpen-${VERSION}-${target}.tar.gz`;
  const tmp = path.join(os.tmpdir(), `bullpen-install-${process.pid}`);
  const tarball = `${tmp}.tar.gz`;

  console.log(`Downloading bullpen v${VERSION} for ${target}...`);
  mkdirSync(path.join(__dirname, "bin"), { recursive: true });
  await download(url, tarball);

  const binDir = path.join(__dirname, "bin");
  execFileSync("tar", ["-xzf", tarball, "-C", binDir, "bullpen"]);
  require("fs").renameSync(path.join(binDir, "bullpen"), BIN_PATH);
  chmodSync(BIN_PATH, 0o755);

  try { require("fs").unlinkSync(tarball); } catch (_) {}
  console.log(`bullpen v${VERSION} installed.`);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
