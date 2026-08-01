#!/usr/bin/env bash
# Build the official Luau CLI (needed to run recovered Luraph VM source,
# which uses Luau-only features: `continue`, `buffer`, `bit32`, string.pack).
# Produces ./luau in this directory. Requires git, cmake, a C++ compiler.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

if [ ! -d luau-src ]; then
    git clone --depth 1 https://github.com/luau-lang/luau.git luau-src
fi
cd luau-src
cmake -B build -DCMAKE_BUILD_TYPE=Release -DLUAU_BUILD_CLI=ON
cmake --build build --target Luau.Repl.CLI -j"$(nproc)"
cp build/luau "$here/luau"
echo "built: $here/luau"
