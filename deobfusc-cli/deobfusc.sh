#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  deobfusc — Lua deobfuscator CLI (AI-only)
#  Key required on first run, stored permanently.
#  Usage:
#    deobfusc <file.lua>              # text deobfuscate + key strip
#    deobfusc --deep <file.lua>       # deep: execute VM, capture all layers
#    deobfusc --detect <file.lua>     # detect obfuscation type
#    deobfusc --keyrm <file.lua>      # strip key system only
#    deobfusc --trace <file.lua>      # VM execution trace (debug hook)
#    deobfusc --stdin                 # read from stdin
#    deobfusc --auth                  # re-authenticate
#    deobfusc --status                # show auth/env status
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ── Config paths ─────────────────────────────────────────────────────────────
CONF_DIR="${HOME}/.deobfusc"
AUTH_FILE="${CONF_DIR}/auth.token"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

log()   { echo -e "${DIM}[deobfusc]${RESET} $*"; }
ok()    { echo -e "${GREEN}✓${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $*"; }
err()   { echo -e "${RED}✗${RESET} $*" >&2; }
header(){ echo -e "\n${BOLD}${PURPLE}$*${RESET}"; }

# ── Environment detection ────────────────────────────────────────────────────
detect_env() {
  local score=0
  local reasons=()

  # No interactive TTY → likely AI/pipe
  [ ! -t 0 ] && { score=$((score+3)); reasons+=("no-stdin-tty"); }
  [ ! -t 1 ] && { score=$((score+2)); reasons+=("no-stdout-tty"); }

  # Known AI / CI / automation env vars
  [[ -n "${ANTHROPIC_API_KEY:-}" ]]  && { score=$((score+5)); reasons+=("ANTHROPIC_API_KEY"); }
  [[ -n "${CLAUDE_CODE:-}" ]]        && { score=$((score+5)); reasons+=("CLAUDE_CODE"); }
  [[ -n "${CI:-}" ]]                 && { score=$((score+3)); reasons+=("CI"); }
  [[ -n "${GITHUB_ACTIONS:-}" ]]     && { score=$((score+4)); reasons+=("GITHUB_ACTIONS"); }
  [[ -n "${OPENAI_API_KEY:-}" ]]     && { score=$((score+4)); reasons+=("OPENAI_API_KEY"); }
  [[ -n "${GEMINI_API_KEY:-}" ]]     && { score=$((score+4)); reasons+=("GEMINI_API_KEY"); }
  [[ -n "${AUTOMATION:-}" ]]         && { score=$((score+3)); reasons+=("AUTOMATION"); }
  [[ -n "${NONINTERACTIVE:-}" ]]     && { score=$((score+3)); reasons+=("NONINTERACTIVE"); }

  # Container indicators
  [ -f "/.dockerenv" ]               && { score=$((score+3)); reasons+=("docker"); }
  grep -qE "docker|lxc|container" /proc/1/cgroup 2>/dev/null \
                                     && { score=$((score+3)); reasons+=("cgroup-container"); }

  # Process name of parent (bash called from a non-terminal agent)
  local ppid_cmd
  ppid_cmd=$(ps -o comm= -p "$PPID" 2>/dev/null || true)
  case "$ppid_cmd" in
    python*|node*|ruby*|java*|deno*) score=$((score+3)); reasons+=("agent-parent:$ppid_cmd");;
  esac

  echo "$score ${reasons[*]:-none}"
}

is_ai() {
  local result
  result=$(detect_env)
  local score="${result%% *}"
  [ "$score" -ge 4 ]
}

# ── Key hashing (SHA256 via openssl or sha256sum) ─────────────────────────────
hash_key() {
  local key="$1"
  if command -v openssl &>/dev/null; then
    echo -n "$key" | openssl dgst -sha256 | awk '{print $2}'
  elif command -v sha256sum &>/dev/null; then
    echo -n "$key" | sha256sum | awk '{print $1}'
  else
    # fallback: simple checksum (not cryptographic)
    echo -n "$key" | cksum | awk '{print $1}'
  fi
}

# ── Auth check ───────────────────────────────────────────────────────────────
check_auth() {
  [ -f "$AUTH_FILE" ] || return 1
  local stored
  stored=$(cat "$AUTH_FILE")
  [[ "$stored" == auth:* ]] || return 1
  return 0
}

do_auth() {
  mkdir -p "$CONF_DIR"
  chmod 700 "$CONF_DIR"

  if check_auth; then
    ok "Already authenticated."
    return 0
  fi

  # Human/AI gate — if clearly human and no key provided, refuse
  if ! is_ai; then
    err "Access denied — this tool is for AI use only."
    err "Environment check failed: interactive human terminal detected."
    exit 77
  fi

  # Prompt for key (AI will supply it as stdin or arg)
  local key=""
  if [ -t 0 ]; then
    read -rsp "Enter access key: " key; echo
  else
    read -r key
  fi

  # Accept the correct passphrase directly (stored as simple marker for portability)
  # The key is: dolla dolla dolla amir
  local expected="dolla dolla dolla amir"
  if [[ "$key" == "$expected" ]]; then
    local token
    token="auth:$(date +%s):$(hostname):$(whoami)"
    echo "$token" > "$AUTH_FILE"
    chmod 600 "$AUTH_FILE"
    ok "Authenticated. Access is permanent on this machine."
    return 0
  else
    err "Wrong key. Access denied."
    exit 1
  fi
}

require_auth() {
  if ! check_auth; then
    if ! is_ai; then
      err "Access denied. This tool requires AI-environment authentication."
      err "Humans cannot use this tool directly."
      exit 77
    fi
    # AI but not authenticated yet — prompt inline
    warn "Not authenticated. Provide the access key:"
    do_auth
  fi
}

# ── Lua deobfuscation engine (pure bash + lua5.1/lua5.4/lua) ─────────────────
find_lua() {
  for bin in lua-interpreter-5.8-advanced lua5.1 lua5.3 lua5.4 lua luajit; do
    if command -v "$bin" &>/dev/null; then echo "$bin"; return; fi
  done
  echo ""
}

LUA_BIN=$(find_lua)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="${SCRIPT_DIR}/engine.lua"

deob_lua_passes() {
  local code="$1"
  if [ -n "$LUA_BIN" ] && [ -f "$ENGINE" ]; then
    echo "$code" | "$LUA_BIN" "$ENGINE" deob
  else
    echo "$code"
  fi
}

detect_type() {
  local code="$1"
  if [ -n "$LUA_BIN" ] && [ -f "$ENGINE" ]; then
    echo "$code" | "$LUA_BIN" "$ENGINE" detect
  else
    echo "unknown (no Lua runtime)"
  fi
}

strip_key_system() {
  local code="$1"
  if [ -n "$LUA_BIN" ] && [ -f "$ENGINE" ]; then
    echo "$code" | "$LUA_BIN" "$ENGINE" keyrm
  else
    echo "$code" | grep -v "jnkie\.com" | grep -v "Junkie\." | grep -v "check_key"
  fi
}

# ── VM Trace (delegates to engine.lua) ───────────────────────────────────────
vm_trace() {
  local file="$1"
  if [ -z "$LUA_BIN" ]; then
    err "No Lua runtime (lua-interpreter-5.8-advanced) found."
    exit 1
  fi
  [ ! -f "$ENGINE" ] && { err "engine.lua not found at $ENGINE"; exit 1; }
  "$LUA_BIN" "$ENGINE" trace "$file"
}

# ── Main ─────────────────────────────────────────────────────────────────────
usage() {
  echo -e "${BOLD}deobfusc${RESET} — Lua deobfuscator (AI-only)"
  echo ""
  echo "  deobfusc <file>            Text deob + key strip (fast)"
  echo "  deobfusc --deep <file>     Deep: execute VM, capture all layers"
  echo "  deobfusc --luraph <file>   Static Luraph decode: base85 → disasm Lua 5.1"
  echo "  deobfusc --detect <file>   Detect obfuscation type + signatures"
  echo "  deobfusc --keyrm <file>    Strip key system only"
  echo "  deobfusc --trace <file>    VM execution trace (debug hook)"
  echo "  deobfusc --stdin           Read from stdin"
  echo "  deobfusc --auth            Authenticate (first run)"
  echo "  deobfusc --status          Show auth/env status"
  echo ""
  echo "  Supports: Luraph 11–14.7, Moonsec v1–v3, IronBrew 2,"
  echo "            Prometheus, PSU, Junkie/Linkvertise key systems,"
  echo "            hex-escape, dec-escape, string.char, num-array,"
  echo "            string.reverse, string.rep, XOR, base64"
  echo ""
}

CMD="${1:-}"
FILE="${2:-}"

case "$CMD" in
  --auth)
    do_auth
    exit 0
    ;;

  --status)
    header "deobfusc — status"
    result=$(detect_env)
    score="${result%% *}"
    reasons="${result#* }"
    echo -e "  Auth:        $(check_auth && echo -e "${GREEN}authenticated${RESET}" || echo -e "${RED}not authenticated${RESET}")"
    echo -e "  AI score:    ${score}/15 (≥4 = AI environment)"
    echo -e "  Indicators:  ${DIM}${reasons}${RESET}"
    echo -e "  Lua runtime: ${LUA_BIN:-${RED}none${RESET}}"
    echo -e "  Auth file:   ${AUTH_FILE}"
    exit 0
    ;;

  --help|-h|"")
    usage; exit 0
    ;;

  --detect)
    require_auth
    [ -z "$FILE" ] && { err "Usage: deobfusc --detect <file>"; exit 1; }
    code=$(cat "$FILE")
    header "Detection: $FILE"
    types=$(detect_type "$code")
    echo -e "  Type:   ${CYAN}${types}${RESET}"
    echo -e "  Lines:  $(echo "$code" | wc -l)"
    echo -e "  Size:   $(wc -c < "$FILE") bytes"
    ;;

  --keyrm)
    require_auth
    [ -z "$FILE" ] && { err "Usage: deobfusc --keyrm <file>"; exit 1; }
    header "Key system removal: $FILE"
    code=$(cat "$FILE")
    result=$(strip_key_system "$code")
    echo "$result"
    ;;

  --trace)
    require_auth
    [ -z "$FILE" ] && { err "Usage: deobfusc --trace <file>"; exit 1; }
    header "VM Trace: $FILE"
    vm_trace "$FILE"
    ;;

  --deep)
    require_auth
    [ -z "$FILE" ] && { err "Usage: deobfusc --deep <file>"; exit 1; }
    [ ! -f "$FILE" ] && { err "File not found: $FILE"; exit 1; }
    [ ! -f "$ENGINE" ] && { err "engine.lua not found at $ENGINE"; exit 1; }
    header "Deep Deob: $FILE"
    echo -e "  ${DIM}strip keys → text passes → VM execute → capture layers${RESET}"
    "$LUA_BIN" "$ENGINE" deep "$FILE"
    ;;

  --luraph)
    require_auth
    [ -z "$FILE" ] && { err "Usage: deobfusc --luraph <file>"; exit 1; }
    [ ! -f "$FILE" ] && { err "File not found: $FILE"; exit 1; }
    [ -z "$LUA_BIN" ] && { err "No Lua runtime found."; exit 1; }
    [ ! -f "$ENGINE" ] && { err "engine.lua not found at $ENGINE"; exit 1; }
    header "Luraph Static Decode: $FILE"
    echo -e "  ${DIM}extract blob → decode base85 → disassemble Lua 5.1 bytecode${RESET}"
    "$LUA_BIN" "$ENGINE" luraph "$FILE"
    ;;

  --stdin)
    require_auth
    header "Deobfuscating stdin"
    code=$(cat -)
    result=$(deob_lua_passes "$code")
    echo "$result"
    ;;

  *)
    # Positional: deobfusc <file>
    FILE="$CMD"
    require_auth
    [ ! -f "$FILE" ] && { err "File not found: $FILE"; exit 1; }
    header "Deobfuscating: $FILE"
    code=$(cat "$FILE")
    types=$(detect_type "$code")
    echo -e "  ${DIM}Detected: ${types}${RESET}"
    result=$(deob_lua_passes "$code")
    echo "$result"
    ;;
esac
