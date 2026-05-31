#!/bin/bash
set -euo pipefail

GLEAM_VERSION="1.16.0"

# apt-get install -y erlang

curl -fsSL "https://github.com/gleam-lang/gleam/releases/download/v${GLEAM_VERSION}/gleam-v${GLEAM_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
  | tar -xz -C /usr/local/bin

gleam --version

cd site
gleam run -m build
