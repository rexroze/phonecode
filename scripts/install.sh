#!/bin/sh
# PhoneCode interactive installer.
# Run from Termux. It installs Ubuntu/proot tooling and PhoneCode helpers.

set -eu

PHONECODE_VERSION="0.3.0-draft"
DRY_RUN=0
PROFILE=""
NON_INTERACTIVE=0
LOG_FILE="${TMPDIR:-/tmp}/phonecode-install.log"
CURRENT_STEP=""
CURRENT_TOTAL=""
CURRENT_LABEL=""

INSTALL_UBUNTU=1
INSTALL_TMUX=1
INSTALL_NODE=1
INSTALL_CODE_SERVER=1
INSTALL_F5=0
INSTALL_OPENCODE=1
INSTALL_GH=1
INSTALL_VERCEL=0
INSTALL_NEON=0
INSTALL_OA=0
RUN_UNINSTALL=0
RUN_REPAIR=0
PHONECODE_NAME="root"
GIT_NAME="PhoneCode User"
GIT_EMAIL="user@phonecode.local"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    DIM='\033[2m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    CYAN=''
    GREEN=''
    YELLOW=''
    RED=''
    BLUE=''
    DIM=''
    BOLD=''
    NC=''
fi

info() { printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$*"; }
warn() { printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$*"; }
fail() { printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$*"; exit 1; }

brand_phone() {
    printf "%b" "$CYAN"
    cat <<'BRAND'
      __________________
     /  ______________  \
    |  |              |  |
    |  |  phonecode   |  |
    |  |  >_ build    |  |
    |  |  >_ ship     |  |
    |  |______________|  |
     \______ ____ ______/
            \____/

BRAND
    printf "%b" "$NC"
    printf "     %bcode from your phone%b\n" "$GREEN" "$NC"
}

brand() {
    brand_phone
}

usage() {
    cat <<'USAGE'
Usage: sh scripts/install.sh [options]

Options:
  --profile NAME       recommended, minimal, custom, repair, uninstall
  --dry-run, -n        Show what would happen without changing files
  --yes, -y            Use defaults and avoid installer questions where possible
  --minimal            Same as --profile minimal
  --recommended        Same as --profile recommended
  --custom             Same as --profile custom
  --repair             Same as --profile repair
  --uninstall          Same as --profile uninstall
  --help, -h           Show this help
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --profile)
            shift
            [ "$#" -gt 0 ] || fail "--profile needs a value"
            PROFILE="$1"
            ;;
        --dry-run|-n)
            DRY_RUN=1
            ;;
        --yes|-y)
            NON_INTERACTIVE=1
            ;;
        --minimal)
            PROFILE="minimal"
            ;;
        --recommended)
            PROFILE="recommended"
            ;;
        --custom)
            PROFILE="custom"
            ;;
        --repair)
            PROFILE="repair"
            ;;
        --uninstall)
            PROFILE="uninstall"
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            fail "Unknown option: $1"
            ;;
    esac
    shift
done

progress_percent() {
    current="$1"
    total="$2"
    printf '%s' "$((current * 100 / total))"
}

terminal_columns() {
    cols="$(tput cols 2>/dev/null || printf '80')"
    case "$cols" in
        ''|*[!0-9]*) cols=80 ;;
    esac
    [ "$cols" -gt 8 ] || cols=80
    printf '%s' "$cols"
}

shorten_text() {
    text="$1"
    max="$2"
    if [ "$max" -le 0 ]; then
        printf ''
        return 0
    fi
    if [ "${#text}" -le "$max" ]; then
        printf '%s' "$text"
    elif [ "$max" -le 3 ]; then
        printf '%s' "$text" | cut -c 1-"$max"
    else
        printf '%s...' "$(printf '%s' "$text" | cut -c 1-$((max - 3)))"
    fi
}

render_step() {
    percent="$(progress_percent "$CURRENT_STEP" "$CURRENT_TOTAL")"
    prefix="[$CURRENT_STEP/$CURRENT_TOTAL] "
    suffix=" ${percent}%"
    if [ -t 1 ] && [ "$DRY_RUN" -eq 0 ]; then
        cols="$(terminal_columns)"
        max_label=$((cols - ${#prefix} - ${#suffix} - 1))
        if [ "$max_label" -lt 8 ]; then
            prefix="Step $CURRENT_STEP/$CURRENT_TOTAL "
            max_label=$((cols - ${#prefix} - ${#suffix} - 1))
        fi
        label="$(shorten_text "$CURRENT_LABEL" "$max_label")"
        printf "\r\033[K%b%s%b%s%b%s%b" "$BLUE" "$prefix" "$NC" "$label" "$GREEN" "$suffix" "$NC"
    else
        printf "%b%s%b%s%b%s%b\n" "$BLUE" "$prefix" "$NC" "$CURRENT_LABEL" "$GREEN" "$suffix" "$NC"
    fi
}

finish_progress_line() {
    if [ -t 1 ] && [ "$DRY_RUN" -eq 0 ]; then
        printf '\n'
    fi
}

wait_for_progress() {
    pid="$1"
    status_file="$2"
    while [ ! -f "$status_file" ]; do
        render_step
        sleep 1
    done
    status="$(sed -n '1p' "$status_file" 2>/dev/null || printf '1')"
    rm -f "$status_file"
    wait "$pid" 2>/dev/null || true
    render_step
    if [ "$status" -ne 0 ]; then
        finish_progress_line
        fail "Command failed during: $CURRENT_LABEL (see $LOG_FILE)"
    fi
}

run() {
    printf '%s\n' "+ $*" >> "$LOG_FILE"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "  dry-run: %s\n" "$*"
        return 0
    fi
    status_file="${TMPDIR:-/tmp}/phonecode-status.$$.$CURRENT_STEP"
    rm -f "$status_file"
    (
        set +e
        "$@" >> "$LOG_FILE" 2>&1
        printf '%s\n' "$?" > "$status_file"
    ) &
    wait_for_progress "$!" "$status_file"
}

pkg_run() {
    run env DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFOLD=1 pkg "$@" -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
}

ask_yes_no() {
    prompt="$1"
    default="$2"
    if [ "$NON_INTERACTIVE" -eq 1 ]; then
        [ "$default" = "y" ]
        return $?
    fi
    case "$default" in
        y) suffix="Y/n" ;;
        *) suffix="y/N" ;;
    esac
    printf "%s [%s]: " "$prompt" "$suffix"
    read -r answer || answer=""
    answer="${answer:-$default}"
    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

step() {
    CURRENT_STEP="$1"
    CURRENT_TOTAL="$2"
    CURRENT_LABEL="$3"
    render_step
}

choose_profile() {
    [ -n "$PROFILE" ] && return 0
    if [ "$NON_INTERACTIVE" -eq 1 ]; then
        PROFILE="recommended"
        return 0
    fi
    brand
    cat <<'MENU'

Welcome to PhoneCode setup.

Choose install type:

  1) Recommended  - phone-first web dev setup
  2) Minimal      - only the basics
  3) Custom       - choose what gets installed
  4) Repair       - reinstall PhoneCode helpers only
  5) Dry run      - preview without changing files
  6) Uninstall    - remove PhoneCode-owned files

MENU
    printf "Select [1-6]: "
    read -r choice || choice="1"
    case "${choice:-1}" in
        1) PROFILE="recommended" ;;
        2) PROFILE="minimal" ;;
        3) PROFILE="custom" ;;
        4) PROFILE="repair" ;;
        5) PROFILE="recommended"; DRY_RUN=1 ;;
        6) PROFILE="uninstall" ;;
        *) PROFILE="recommended" ;;
    esac
}

apply_profile() {
    case "$PROFILE" in
        recommended)
            INSTALL_UBUNTU=1
            INSTALL_TMUX=1
            INSTALL_NODE=1
            INSTALL_CODE_SERVER=1
            INSTALL_F5=0
            INSTALL_OPENCODE=1
            INSTALL_GH=1
            INSTALL_VERCEL=1
            INSTALL_NEON=1
            INSTALL_OA=1
            ;;
        minimal)
            INSTALL_UBUNTU=1
            INSTALL_TMUX=1
            INSTALL_NODE=1
            INSTALL_CODE_SERVER=0
            INSTALL_F5=0
            INSTALL_OPENCODE=0
            INSTALL_GH=0
            INSTALL_VERCEL=0
            INSTALL_NEON=0
            INSTALL_OA=0
            ;;
        custom)
            custom_questions
            ;;
        repair)
            RUN_REPAIR=1
            INSTALL_UBUNTU=0
            INSTALL_TMUX=0
            INSTALL_NODE=0
            INSTALL_CODE_SERVER=0
            INSTALL_F5=0
            INSTALL_OPENCODE=0
            INSTALL_GH=0
            INSTALL_VERCEL=0
            INSTALL_NEON=0
            INSTALL_OA=0
            ;;
        uninstall)
            RUN_UNINSTALL=1
            ;;
        *)
            fail "Unknown profile: $PROFILE"
            ;;
    esac
}

custom_questions() {
    cat <<'CUSTOM'

PhoneCode Custom Setup
Answer once now. After this, PhoneCode installs without random prompts where possible.
CUSTOM
    if ask_yes_no "Install and configure Ubuntu through proot-distro?" y; then
        INSTALL_UBUNTU=1
    else
        INSTALL_UBUNTU=0
        INSTALL_TMUX=0
        INSTALL_NODE=0
        INSTALL_CODE_SERVER=0
        INSTALL_F5=0
        INSTALL_OPENCODE=0
        INSTALL_GH=0
        INSTALL_VERCEL=0
        INSTALL_NEON=0
        INSTALL_OA=0
        warn "Skipping Ubuntu also skips Ubuntu-side PhoneCode helpers and tools."
        return 0
    fi
    ask_yes_no "Configure tmux?" y && INSTALL_TMUX=1 || INSTALL_TMUX=0
    ask_yes_no "Install Node.js LTS through nvm?" y && INSTALL_NODE=1 || INSTALL_NODE=0
    ask_yes_no "Install code-server?" y && INSTALL_CODE_SERVER=1 || INSTALL_CODE_SERVER=0
    ask_yes_no "Enable F5 open-app behavior?" n && INSTALL_F5=1 || INSTALL_F5=0
    ask_yes_no "Install OpenCode?" y && INSTALL_OPENCODE=1 || INSTALL_OPENCODE=0
    ask_yes_no "Install GitHub CLI?" y && INSTALL_GH=1 || INSTALL_GH=0
    ask_yes_no "Install Vercel CLI?" n && INSTALL_VERCEL=1 || INSTALL_VERCEL=0
    ask_yes_no "Install Neon CLI?" n && INSTALL_NEON=1 || INSTALL_NEON=0
    ask_yes_no "Add optional 'oa' shortcut for 'ocode --auto'?" n && INSTALL_OA=1 || INSTALL_OA=0
}

sanitize_label() {
    value="$(printf '%s' "$1" | sed 's/[^A-Za-z0-9_-]/-/g; s/--*/-/g; s/^-//; s/-$//')"
    printf '%s\n' "${value:-root}"
}

ask_text() {
    prompt="$1"
    default="$2"
    if [ "$NON_INTERACTIVE" -eq 1 ]; then
        printf '%s\n' "$default"
        return 0
    fi
    printf "%s [%s]: " "$prompt" "$default" >&2
    read -r answer || answer=""
    printf '%s\n' "${answer:-$default}"
}

collect_identity() {
    [ "$RUN_UNINSTALL" -eq 1 ] && return 0
    [ "$RUN_REPAIR" -eq 0 ] && [ "$INSTALL_UBUNTU" -eq 0 ] && return 0
    PHONECODE_NAME="$(sanitize_label "$(ask_text "PhoneCode terminal name" "$PHONECODE_NAME")")"
    GIT_NAME="$(ask_text "Git name" "$GIT_NAME")"
    GIT_EMAIL="$(ask_text "Git email" "$GIT_EMAIL")"
}

confirm_summary() {
    [ "$RUN_UNINSTALL" -eq 1 ] && return 0
    cat <<SUMMARY

Install summary
  Profile:             $PROFILE
  Ubuntu/proot:         $INSTALL_UBUNTU
  tmux config:          $INSTALL_TMUX
  Node.js LTS:          $INSTALL_NODE
  code-server:          $INSTALL_CODE_SERVER
  F5 behavior:          $INSTALL_F5
  OpenCode:             $INSTALL_OPENCODE
  GitHub CLI:           $INSTALL_GH
  Vercel CLI:           $INSTALL_VERCEL
  Neon CLI:             $INSTALL_NEON
  oa shortcut:          $INSTALL_OA
  Terminal name:        $PHONECODE_NAME
  Git identity:         $GIT_NAME <$GIT_EMAIL>
  Dry run:              $DRY_RUN

SUMMARY
    [ "$NON_INTERACTIVE" -eq 1 ] && return 0
    ask_yes_no "Continue?" y || exit 0
}

termux_guard() {
    if [ -z "${PREFIX:-}" ] || ! command -v pkg >/dev/null 2>&1; then
        if [ "$DRY_RUN" -eq 1 ]; then
            warn "This does not look like Termux. Continuing because this is a dry run."
        else
            fail "Run this from Termux, not from inside Ubuntu/proot."
        fi
    fi
}

create_start_command() {
    START_PATH="${PREFIX:-/data/data/com.termux/files/usr}/bin/start"
    step 4 7 "Installing Termux start command"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "  dry-run: inspect %s and create/update only if PhoneCode owns it\n" "$START_PATH"
        return 0
    fi
    if [ -f "$START_PATH" ]; then
        if cmp -s "$START_PATH" - <<'OLDSTARTEOF'
#!/bin/sh
exec proot-distro login ubuntu
OLDSTARTEOF
        then
            printf '%s\n' "Updating existing PhoneCode start command." >> "$LOG_FILE"
        elif grep -q 'phonecode' "$START_PATH" 2>/dev/null && grep -q 'proot-distro login ubuntu' "$START_PATH" 2>/dev/null; then
            printf '%s\n' "Updating existing PhoneCode start command." >> "$LOG_FILE"
        else
            finish_progress_line
            warn "'start' already exists at $START_PATH; leaving it unchanged."
            return 0
        fi
    fi
    cat > "$START_PATH" <<'STARTEOF'
#!/bin/sh
# PhoneCode-owned Termux launcher.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    CYAN='\033[0;36m'
    GREEN='\033[0;32m'
    DIM='\033[2m'
    NC='\033[0m'
else
    CYAN=''
    GREEN=''
    DIM=''
    NC=''
fi
brand_phone() {
    printf "%b" "$CYAN"
    cat <<'BRAND'
      __________________
     /  ______________  \
    |  |              |  |
    |  |  phonecode   |  |
    |  |  >_ build    |  |
    |  |  >_ ship     |  |
    |  |______________|  |
     \______ ____ ______/
            \____/

BRAND
    printf "%b" "$NC"
    printf "     %bcode from your phone%b\n" "$GREEN" "$NC"
}
brand_phone
exec proot-distro login ubuntu -- bash -i
STARTEOF
    chmod +x "$START_PATH"
}

remove_start_command() {
    START_PATH="${PREFIX:-/data/data/com.termux/files/usr}/bin/start"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "  dry-run: remove %s only if PhoneCode owns it\n" "$START_PATH"
        return 0
    fi
    [ -f "$START_PATH" ] || return 0
    if grep -q 'PhoneCode-owned Termux launcher' "$START_PATH" 2>/dev/null; then
        rm -f "$START_PATH"
    elif cmp -s "$START_PATH" - <<'OLDSTARTEOF'
#!/bin/sh
exec proot-distro login ubuntu
OLDSTARTEOF
    then
        rm -f "$START_PATH"
    else
        warn "'start' exists at $START_PATH but is not PhoneCode-owned; leaving it unchanged."
    fi
}

install_termux_layer() {
    step 1 7 "Updating Termux packages"
    pkg_run update -y
    pkg_run upgrade -y
    step 2 7 "Installing Termux tools"
    pkg_run install -y proot-distro git curl openssh nano tmux
    step 3 7 "Installing Ubuntu if needed"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "  dry-run: proot-distro install ubuntu if missing\n"
    elif proot-distro list 2>/dev/null | grep -q '^ *ubuntu '; then
        printf '%s\n' "Ubuntu is already installed." >> "$LOG_FILE"
    else
        run proot-distro install ubuntu
    fi
    create_start_command
}

run_ubuntu_install() {
    step 5 7 "Setting up Ubuntu tools and PhoneCode commands"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "  dry-run: proot-distro login ubuntu -- install selected tools\n"
        return 0
    fi
    status_file="${TMPDIR:-/tmp}/phonecode-status.$$.$CURRENT_STEP"
    rm -f "$status_file"
    (
    set +e
    proot-distro login ubuntu -- env \
        PHONECODE_VERSION="$PHONECODE_VERSION" \
        PROFILE="$PROFILE" \
        INSTALL_TMUX="$INSTALL_TMUX" \
        INSTALL_NODE="$INSTALL_NODE" \
        INSTALL_CODE_SERVER="$INSTALL_CODE_SERVER" \
        INSTALL_F5="$INSTALL_F5" \
        INSTALL_OPENCODE="$INSTALL_OPENCODE" \
        INSTALL_GH="$INSTALL_GH" \
        INSTALL_VERCEL="$INSTALL_VERCEL" \
        INSTALL_NEON="$INSTALL_NEON" \
        INSTALL_OA="$INSTALL_OA" \
        RUN_REPAIR="$RUN_REPAIR" \
        PHONECODE_NAME="$PHONECODE_NAME" \
        GIT_NAME="$GIT_NAME" \
        GIT_EMAIL="$GIT_EMAIL" \
        sh <<'UBUNTU_SCRIPT'
set -eu
export DEBIAN_FRONTEND=noninteractive

backup_file() {
    file="$1"
    [ -f "$file" ] || return 0
    stamp="$(date +%Y%m%d-%H%M%S)"
    cp "$file" "$file.phonecode.bak.$stamp"
}

if [ "${RUN_REPAIR:-0}" != "1" ]; then
    apt-get update -y
    apt-get upgrade -y \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold"
    apt-get install -y git curl ca-certificates build-essential nano jq python3
fi

if [ "${RUN_REPAIR:-0}" != "1" ] && [ "${INSTALL_TMUX:-1}" = "1" ]; then
    apt-get install -y tmux
    backup_file "$HOME/.tmux.conf"
    cat > "$HOME/.tmux.conf" <<'TMUXEOF'
set -g mouse on
set -g history-limit 5000
set -g base-index 1
setw -g pane-base-index 1
TMUXEOF
fi

mkdir -p "$HOME/projects" "$HOME/.local/bin" "$HOME/.local/share/phonecode" "$HOME/.config/phonecode"

if [ "${RUN_REPAIR:-0}" != "1" ] && [ "${INSTALL_GH:-0}" = "1" ] && ! command -v gh >/dev/null 2>&1; then
    if ! apt-get install -y gh; then
        mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
        chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
        apt-get update -y
        apt-get install -y gh
    fi
fi

git config --global user.name "$GIT_NAME" || true
git config --global user.email "$GIT_EMAIL" || true
git config --global init.defaultBranch main || true
git config --global credential.helper cache || true

if [ "${RUN_REPAIR:-0}" != "1" ] && [ "${INSTALL_NODE:-1}" = "1" ]; then
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    set +u
    # shellcheck disable=SC1091
    . "$NVM_DIR/nvm.sh"
    if ! command -v node >/dev/null 2>&1; then
        nvm install --lts
    fi
    nvm use --lts
    set -u
    corepack enable || true
    npm_tools=""
    [ "${INSTALL_OPENCODE:-0}" = "1" ] && npm_tools="$npm_tools opencode-ai"
    [ "${INSTALL_VERCEL:-0}" = "1" ] && npm_tools="$npm_tools vercel"
    [ "${INSTALL_NEON:-0}" = "1" ] && npm_tools="$npm_tools neon"
    [ -n "$npm_tools" ] && npm install -g $npm_tools
fi

if [ "${RUN_REPAIR:-0}" != "1" ] && [ "${INSTALL_CODE_SERVER:-0}" = "1" ] && ! command -v code-server >/dev/null 2>&1; then
    curl -fsSL https://code-server.dev/install.sh | sh
fi

cat > "$HOME/.local/share/phonecode/helpers.sh" <<'HELPERS'
# PhoneCode shell helpers. Sourced by ~/.bashrc.
export PATH="$HOME/.local/bin:$PATH"
export PHONECODE_HOST="phonecode"
export PHONECODE_NAME="PHONECODE_NAME_PLACEHOLDER"

if [ -n "${BASH_VERSION:-}" ]; then
    PS1='\[\033[0;32m\]${PHONECODE_NAME}@${PHONECODE_HOST}\[\033[0m\]:\[\033[0;34m\]\w\[\033[0m\]\$ '
fi

code() {
    phonecode code "$@"
}

open() {
    phonecode open "$@"
}
HELPERS
phonecode_name_escaped="$(printf '%s' "${PHONECODE_NAME:-root}" | sed 's/[\/&]/\\&/g')"
sed -i "s/PHONECODE_NAME_PLACEHOLDER/$phonecode_name_escaped/g" "$HOME/.local/share/phonecode/helpers.sh"
agent_command="ocode --auto"
[ "${INSTALL_OA:-0}" = "1" ] && agent_command="oa"
agent_command_escaped="$(printf '%s' "$agent_command" | sed 's/[\/&]/\\&/g')"

cat > "$HOME/.local/bin/phonecode" <<'PHONECODE'
#!/bin/sh
set -u
VERSION="0.3.0-draft"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/phonecode"
CODE_STATE="/tmp/phonecode-code-server"
mkdir -p "$STATE_DIR" "$CODE_STATE"
say() { printf '%s\n' "$*"; }
pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; }
usage() {
    cat <<'USAGE'
Usage: phonecode COMMAND [args]

Aliases:
  pc                 Short alias for phonecode
  code               Shell helper for phonecode code
  open               Shell helper for phonecode open
  ocode              Safe OpenCode wrapper
  start              Termux command that enters Ubuntu

Commands:
  doctor             Check the PhoneCode environment
  verify             Alias for doctor
  code [path]        Start code-server safely for a folder
  code ls            List PhoneCode code-server sessions
  code stop [index]  Stop one or all PhoneCode code-server sessions
  code lan [path]    Start code-server on LAN with password auth
  password [args]    Show, set, or rotate code-server password
  open URL           Open a URL through Android/desktop helpers
  opencode [args]    Run OpenCode only inside a specific project folder
  install-f5         Install code-server F5 open-app tasks
  stop-all           Stop PhoneCode sessions
  uninstall          Remove PhoneCode-owned files
  help               Show this help

Quick start:
  start
  pc doctor
  pc help
  mkdir -p ~/projects/my-app
  cd ~/projects/my-app
  code .
  PHONECODE_AGENT_COMMAND_PLACEHOLDER
USAGE
}
is_bad_agent_dir() {
    here="$(pwd -P 2>/dev/null || pwd)"
    projects="$(cd "$HOME/projects" 2>/dev/null && pwd -P || printf '%s/projects' "$HOME")"
    home="$(cd "$HOME" 2>/dev/null && pwd -P || printf '%s' "$HOME")"
    case "$here" in /root|"$home"|"$projects") return 0 ;; *) return 1 ;; esac
}
cmd_opencode() {
    if is_bad_agent_dir; then
        cat <<EOM
Refusing to start OpenCode from: $(pwd)

Go into a specific project first:
  mkdir -p ~/projects/my-app
  cd ~/projects/my-app
  PHONECODE_AGENT_COMMAND_PLACEHOLDER

Normal OpenCode is still available:
  opencode $*
EOM
        return 1
    fi
    exec opencode "$@"
}
cmd_open() {
    [ -n "${1:-}" ] || { say "Usage: phonecode open URL"; return 2; }
    export PATH="/data/data/com.termux/files/usr/bin:$PATH"
    if command -v termux-open-url >/dev/null 2>&1; then exec termux-open-url "$1"; fi
    if [ -x /data/data/com.termux/files/usr/bin/termux-open-url ]; then exec /data/data/com.termux/files/usr/bin/termux-open-url "$1"; fi
    if command -v sensible-browser >/dev/null 2>&1; then exec sensible-browser "$1"; fi
    if command -v xdg-open >/dev/null 2>&1; then exec xdg-open "$1"; fi
    say "Open this URL in your Android browser:"
    say "$1"
}
password_file() { printf '%s\n' "$HOME/.config/code-server/config.yaml"; }
cmd_password() {
    config="$(password_file)"
    mkdir -p "$(dirname "$config")"
    case "${1:-show}" in
        show)
            if [ -f "$config" ] && grep -q '^password:' "$config"; then sed -n 's/^password:[[:space:]]*//p' "$config" | tail -n 1; else say "No code-server password configured. Run: phonecode password rotate"; return 1; fi
            ;;
        set)
            [ -n "${2:-}" ] || { say "Usage: phonecode password set NEW_PASSWORD"; return 2; }
            printf 'bind-addr: 127.0.0.1:8080\nauth: password\npassword: %s\ncert: false\n' "$2" > "$config"
            chmod 600 "$config"
            say "code-server password updated."
            ;;
        rotate)
            if command -v node >/dev/null 2>&1; then new="$(node -e 'console.log(require("crypto").randomBytes(15).toString("base64url"))')"; else new="phonecode-$(date +%s)"; fi
            cmd_password set "$new" >/dev/null
            say "$new"
            ;;
        *) say "Usage: phonecode password [show|rotate|set NEW_PASSWORD]"; return 2 ;;
    esac
}
port_free() {
    python3 - "$1" <<'PY' >/dev/null 2>&1
import socket, sys
s = socket.socket()
try: s.bind(("127.0.0.1", int(sys.argv[1])))
finally: s.close()
PY
}
next_port() {
    p=8080
    while [ "$p" -le 8099 ]; do [ ! -f "$CODE_STATE/$p.session" ] && port_free "$p" && { printf '%s\n' "$p"; return 0; }; p=$((p + 1)); done
    return 1
}
folder_url() {
    python3 - "$1" "$2" "$3" <<'PY'
import sys
from urllib.parse import quote
path, host, port = sys.argv[1:4]
if ":" in host and not host.startswith("["): host = f"[{host}]"
print(f"http://{host}:{port}/?folder={quote(path, safe='')}")
PY
}
lan_host() {
    python3 - <<'PY'
import ipaddress, subprocess
items=[]
try: items += subprocess.check_output(["hostname", "-I"], text=True).split()
except Exception: pass
for raw in items:
    value=raw.split('%',1)[0]
    try: ip=ipaddress.ip_address(value)
    except ValueError: continue
    if not (ip.is_loopback or ip.is_link_local or ip.is_unspecified) and ip.version==4:
        print(value); raise SystemExit
print("PHONE_IP")
PY
}
prune_sessions() {
    mkdir -p "$CODE_STATE"
    for s in "$CODE_STATE"/*.session; do [ -f "$s" ] || continue; pid="$(sed -n '1p' "$s")"; [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null || rm -f "$s"; done
}
list_sessions() {
    prune_sessions; i=1; found=0
    for s in "$CODE_STATE"/*.session; do
        [ -f "$s" ] || continue
        pid="$(sed -n '1p' "$s")"; port="$(sed -n '2p' "$s")"; host="$(sed -n '3p' "$s")"; dir="$(sed -n '4,$p' "$s")"
        printf '%s  port=%s  bind=%s  pid=%s  %s\n' "$i" "$port" "$host" "$pid" "$dir"
        i=$((i + 1)); found=1
    done
    [ "$found" -eq 1 ] || say "No code-server sessions running."
}
stop_session_file() {
    s="$1"; [ -f "$s" ] || return 0
    pid="$(sed -n '1p' "$s")"; port="$(sed -n '2p' "$s")"
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
    sleep 1
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
    [ -n "$port" ] && pkill -f "code-server.*:$port" 2>/dev/null || true
    rm -f "$s"
}
stop_sessions() {
    prune_sessions
    if [ -n "${1:-}" ]; then i=1; for s in "$CODE_STATE"/*.session; do [ -f "$s" ] || continue; if [ "$i" = "$1" ]; then stop_session_file "$s"; say "Stopped code-server $1"; return 0; fi; i=$((i + 1)); done; say "No code-server session at index: $1"; return 1; fi
    found=0; for s in "$CODE_STATE"/*.session; do [ -f "$s" ] && stop_session_file "$s" && found=1; done
    [ "$found" -eq 1 ] && say "Stopped all code-server sessions." || say "No code-server sessions running."
}
cmd_code() {
    case "${1:-}" in ls) list_sessions; return 0 ;; stop) shift; stop_sessions "${1:-}"; return $? ;; lan) shift; host="0.0.0.0"; open_host="$(lan_host)"; auth="--auth password"; cmd_password show >/dev/null 2>&1 || cmd_password rotate >/dev/null ;; *) host="127.0.0.1"; open_host="127.0.0.1"; auth="--auth none" ;; esac
    command -v code-server >/dev/null 2>&1 || { say "code-server is not installed."; return 1; }
    dir="${1:-.}"; abs="$(cd "$dir" 2>/dev/null && pwd)" || { say "Directory not found: $dir"; return 1; }
    port="$(next_port)" || { say "No free code-server ports found in 8080-8099."; return 1; }
    log="/tmp/phonecode-code-server-$port.log"; session="$CODE_STATE/$port.session"; user_data="$CODE_STATE/user-$port"; mkdir -p "$user_data/User"
    nohup code-server --ignore-last-opened --disable-workspace-trust --user-data-dir "$user_data" --bind-addr "$host:$port" $auth "$abs" </dev/null >"$log" 2>&1 &
    pid="$!"; printf '%s\n%s\n%s\n%s\n' "$pid" "$port" "$host" "$abs" > "$session"
    url="$(folder_url "$abs" "$open_host" "$port")"; say "code-server running for: $abs"; say "URL: $url"; [ "$host" = "0.0.0.0" ] && say "Password: $(cmd_password show)"; say "Logs: $log"; cmd_open "$url" || true
}
cmd_install_f5() {
    user_dir="${XDG_DATA_HOME:-$HOME/.local/share}/code-server/User"; mkdir -p "$user_dir"
    cat > "$user_dir/tasks.json" <<'TASKS'
{"version":"2.0.0","tasks":[{"label":"Open app","type":"shell","command":"phonecode open ${input:appUrl}","problemMatcher":[]}],"inputs":[{"id":"appUrl","type":"promptString","description":"App URL","default":"http://127.0.0.1:3000"}]}
TASKS
    cat > "$user_dir/keybindings.json" <<'KEYS'
[{"key":"f5","command":"workbench.action.tasks.runTask"}]
KEYS
    say "F5 task picker installed."
}
cmd_doctor() {
    say "PhoneCode doctor"; say "Version: $VERSION"; say ""
    command -v tmux >/dev/null 2>&1 && pass "tmux installed" || fail "tmux missing"
    command -v node >/dev/null 2>&1 && pass "node installed: $(node --version 2>/dev/null)" || warn "node missing"
    command -v npm >/dev/null 2>&1 && pass "npm installed: $(npm --version 2>/dev/null)" || warn "npm missing"
    command -v code-server >/dev/null 2>&1 && pass "code-server installed" || warn "code-server missing"
    command -v gh >/dev/null 2>&1 && pass "gh installed" || warn "gh missing"
    command -v vercel >/dev/null 2>&1 && pass "vercel installed" || warn "vercel missing"
    command -v neon >/dev/null 2>&1 && pass "neon installed" || warn "neon missing"
    command -v opencode >/dev/null 2>&1 && pass "opencode installed" || warn "opencode missing"
    command -v phonecode >/dev/null 2>&1 && pass "phonecode command installed" || fail "phonecode command missing"
    command -v pc >/dev/null 2>&1 && pass "pc shortcut installed" || warn "pc shortcut missing"
    command -v ocode >/dev/null 2>&1 && pass "ocode shortcut installed" || warn "ocode shortcut missing"
    if command -v pgrep >/dev/null 2>&1; then for pid in $(pgrep opencode 2>/dev/null || true); do cwd="$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)"; case "$cwd" in /root|"$HOME"|"$HOME/projects") warn "OpenCode pid $pid is running from broad folder: $cwd" ;; esac; done; fi
    say ""; say "Code-server sessions:"; list_sessions
}
cmd_uninstall() {
    say "Removing PhoneCode-owned files only. Projects are not deleted."; stop_sessions || true
    rm -f "$HOME/.local/bin/phonecode" "$HOME/.local/bin/pc" "$HOME/.local/bin/ocode" "$HOME/.local/bin/oa"
    rm -rf "$HOME/.local/share/phonecode" "$CODE_STATE"
    if [ -f "$HOME/.bashrc" ]; then awk '/### PhoneCode helpers ###/ {skip=1; next} /### End PhoneCode helpers ###/ {skip=0; next} !skip {print}' "$HOME/.bashrc" > "$HOME/.bashrc.phonecode-uninstall"; mv "$HOME/.bashrc.phonecode-uninstall" "$HOME/.bashrc"; fi
    say "PhoneCode files removed. Restart your shell."
}
case "${1:-help}" in
    doctor|verify) cmd_doctor ;;
    code) shift; cmd_code "$@" ;;
    password) shift; cmd_password "$@" ;;
    open) shift; cmd_open "$@" ;;
    opencode) shift; cmd_opencode "$@" ;;
    install-f5) cmd_install_f5 ;;
    stop-all) stop_sessions ;;
    uninstall) cmd_uninstall ;;
    help|--help|-h) usage ;;
    *) usage; exit 2 ;;
esac
PHONECODE
sed -i "s/PHONECODE_AGENT_COMMAND_PLACEHOLDER/$agent_command_escaped/g" "$HOME/.local/bin/phonecode"
chmod +x "$HOME/.local/bin/phonecode"
cat > "$HOME/.local/bin/pc" <<'PC'
#!/bin/sh
exec phonecode "$@"
PC
chmod +x "$HOME/.local/bin/pc"
cat > "$HOME/.local/bin/ocode" <<'OCODE'
#!/bin/sh
exec phonecode opencode "$@"
OCODE
chmod +x "$HOME/.local/bin/ocode"
if [ "${INSTALL_OA:-0}" = "1" ]; then
    cat > "$HOME/.local/bin/oa" <<'OA'
#!/bin/sh
exec ocode --auto "$@"
OA
    chmod +x "$HOME/.local/bin/oa"
fi
HELPER_START='### PhoneCode helpers ###'
HELPER_END='### End PhoneCode helpers ###'
backup_file "$HOME/.bashrc"
if [ -f "$HOME/.bashrc" ] && grep -q "$HELPER_START" "$HOME/.bashrc" 2>/dev/null; then
    awk "index(\$0, \"$HELPER_START\") { skip = 1; next } index(\$0, \"$HELPER_END\") { skip = 0; next } !skip { print }" "$HOME/.bashrc" > "$HOME/.bashrc.phonecode"
    mv "$HOME/.bashrc.phonecode" "$HOME/.bashrc"
fi
cat >> "$HOME/.bashrc" <<'BASHRC'

### PhoneCode helpers ###
[ -f "$HOME/.local/share/phonecode/helpers.sh" ] && . "$HOME/.local/share/phonecode/helpers.sh"
### End PhoneCode helpers ###
BASHRC
cat > "$HOME/.config/phonecode/install.conf" <<CONF
profile=${PROFILE:-recommended}
install_code_server=${INSTALL_CODE_SERVER:-0}
install_f5=${INSTALL_F5:-0}
install_opencode=${INSTALL_OPENCODE:-0}
install_gh=${INSTALL_GH:-0}
install_vercel=${INSTALL_VERCEL:-0}
install_neon=${INSTALL_NEON:-0}
install_oa=${INSTALL_OA:-0}
phonecode_name=${PHONECODE_NAME:-root}
git_name=${GIT_NAME:-PhoneCode User}
git_email=${GIT_EMAIL:-user@phonecode.local}
CONF
[ "${INSTALL_F5:-0}" = "1" ] && "$HOME/.local/bin/phonecode" install-f5 || true
"$HOME/.local/bin/phonecode" doctor || true
UBUNTU_SCRIPT
    printf '%s\n' "$?" > "$status_file"
    ) >> "$LOG_FILE" 2>&1 &
    wait_for_progress "$!" "$status_file"
}

run_uninstall() {
    step 1 3 "Uninstalling PhoneCode helpers"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf "  dry-run: proot-distro login ubuntu -- phonecode uninstall\n"
    else
        proot-distro login ubuntu -- sh -lc 'command -v phonecode >/dev/null 2>&1 && phonecode uninstall || true'
    fi
    step 2 3 "Removing PhoneCode start command"
    remove_start_command
    step 3 3 "Done"
}

main() {
    : > "$LOG_FILE"
    choose_profile
    apply_profile
    collect_identity
    confirm_summary
    brand
    printf "\nPhoneCode is installing...\nLog: %s\n" "$LOG_FILE"
    termux_guard
    if [ "$RUN_UNINSTALL" -eq 1 ]; then run_uninstall; exit 0; fi
    if [ "$RUN_REPAIR" -eq 0 ] && [ "$INSTALL_UBUNTU" -eq 1 ]; then
        install_termux_layer
        run_ubuntu_install
    elif [ "$RUN_REPAIR" -eq 1 ]; then
        run_ubuntu_install
    else
        step 5 7 "Skipping Ubuntu setup"
        warn "Ubuntu setup was skipped by profile choice."
    fi
    step 6 7 "Saving install choices"
    step 7 7 "Finished"
    finish_progress_line
    brand
    if [ "$INSTALL_UBUNTU" -eq 0 ] && [ "$RUN_REPAIR" -eq 0 ]; then
        cat <<'DONE'

PhoneCode setup finished without Ubuntu changes.

Ubuntu/proot setup was skipped, so PhoneCode helpers and tools were not installed inside Ubuntu.
Run again with Recommended, Minimal, or Custom with Ubuntu enabled when you want the full setup.
DONE
    else
        agent_command="ocode --auto"
        [ "$INSTALL_OA" -eq 1 ] && agent_command="oa"
        cat <<DONE

PhoneCode setup is done.

Next:
  start
  pc doctor
  pc help
  mkdir -p ~/projects/my-app
  cd ~/projects/my-app
  code .
  $agent_command
DONE
    fi
}

main "$@"
