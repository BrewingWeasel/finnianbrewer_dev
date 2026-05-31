#!/bin/bash
set -euo pipefail

GLEAM_VERSION="1.16.0"

mkdir -p bin

curl -fsSL "https://github.com/gleam-lang/gleam/releases/download/v${GLEAM_VERSION}/gleam-v${GLEAM_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
  | tar -xz -C ./bin
export PATH="$PWD/bin:$PATH"

gleam --version

cd site
bun install
gleam run -m build

ls -l site/dist
