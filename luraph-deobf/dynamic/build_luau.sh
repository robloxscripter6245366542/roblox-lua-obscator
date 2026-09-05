#!/usr/bin/env bash
# Build the official Luau CLI (needed to run recovered Luraph VM source,
# which uses Luau-only features: `continue`, `buffer`, `bit32`, string.pack)
# plus the Luau.Ast.CLI tool (`luau-ast`, a full JSON AST dumper -- used by
# devirt/ tools that need exact structural extraction instead of regex).
# Produces ./luau and ./luau-ast in this directory. Requires git, cmake, a
# C++ compiler.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

if [ ! -d luau-src ]; then
    git clone --depth 1 https://github.com/luau-lang/luau.git luau-src
fi
cd luau-src
cmake -B build -DCMAKE_BUILD_TYPE=Release -DLUAU_BUILD_CLI=ON
cmake --build build --target Luau.Repl.CLI -j"$(nproc)"
cmake --build build --target Luau.Ast.CLI -j"$(nproc)"
cp build/luau "$here/luau"
cp build/luau-ast "$here/luau-ast"
echo "built: $here/luau"
echo "built: $here/luau-ast"
