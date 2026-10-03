#!/usr/bin/env bash

# game-modder-info.sh
# Read-only environment survey for AI game-modding / recomp projects.
# Makes no system changes and does not read authentication tokens/config files.

set +e

have() {
  command -v "$1" >/dev/null 2>&1
}

tool_info() {
  local name="$1"
  local cmd="${2:-$1}"

  if have "$cmd"; then
    local path version
    path="$(command -v "$cmd")"

    case "$cmd" in
      java)     version="$("$cmd" -version 2>&1 | head -n 1)" ;;
      ghidraRun) version="installed" ;;
      *)        version="$("$cmd" --version 2>&1 | head -n 1)" ;;
    esac

    printf "%-14s YES | %s | %s\n" "$name:" "$path" "$version"
  else
    printf "%-14s NO\n" "$name:"
  fi
}

OS="$(uname -s)"
ARCH="$(uname -m)"
HOST="$(hostname 2>/dev/null)"
SHELL_NAME="${SHELL:-unknown}"

CPU="Unknown"
RAM="Unknown"
GPU="Unknown"
VRAM="Unknown"

if [[ "$OS" == "Darwin" ]]; then
  CPU="$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
  [[ -z "$CPU" ]] && CPU="$(sysctl -n hw.model 2>/dev/null)"

  RAM_BYTES="$(sysctl -n hw.memsize 2>/dev/null)"
  if [[ "$RAM_BYTES" =~ ^[0-9]+$ ]]; then
    RAM="$((RAM_BYTES / 1024 / 1024 / 1024)) GB"
  fi

  GPU="$(system_profiler SPDisplaysDataType 2>/dev/null |
    awk -F': ' '/Chipset Model:/ {print $2; exit}')"

  VRAM="$(system_profiler SPDisplaysDataType 2>/dev/null |
    awk -F': ' '/VRAM.*:/ {print $2; exit}')"

  # Apple Silicon uses unified memory rather than dedicated VRAM.
  if [[ -z "$VRAM" ]] && [[ "$(uname -m)" == "arm64" ]]; then
    VRAM="Unified memory; no dedicated VRAM reported"
  fi

elif [[ "$OS" == "Linux" ]]; then
  CPU="$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null)"

  if have free; then
    RAM="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')"
  fi

  if have lspci; then
    GPU="$(lspci 2>/dev/null |
      grep -Ei 'VGA|3D controller|Display controller' |
      head -n 1 |
      sed 's/^[^ ]* //')"
  fi

  if have nvidia-smi; then
    NVIDIA_NAME="$(nvidia-smi \
      --query-gpu=name \
      --format=csv,noheader 2>/dev/null | head -n 1)"

    NVIDIA_VRAM="$(nvidia-smi \
      --query-gpu=memory.total \
      --format=csv,noheader 2>/dev/null | head -n 1)"

    [[ -n "$NVIDIA_NAME" ]] && GPU="$NVIDIA_NAME"
    [[ -n "$NVIDIA_VRAM" ]] && VRAM="$NVIDIA_VRAM"
  fi
fi

echo
echo "# Game Modding Environment"
echo
echo '```text'
echo "OS:             $OS"
echo "Architecture:   $ARCH"
echo "CPU:            $CPU"
echo "RAM:            $RAM"
echo "GPU:            $GPU"
echo "VRAM:           $VRAM"
echo "Shell:          $SHELL_NAME"
echo '```'

echo
echo "## AI agents"
echo
echo '```text'
tool_info "Claude Code" claude
tool_info "Codex" codex
tool_info "OpenCode" opencode
tool_info "Pi" pi
tool_info "Aider" aider
echo '```'

echo
echo "## Core development tools"
echo
echo '```text'
tool_info "Git" git
tool_info "GitHub CLI" gh
tool_info "Node.js" node
tool_info "npm" npm
tool_info "Python" python3
tool_info "Java" java
tool_info "Rust" rustc
tool_info "Cargo" cargo
tool_info "CMake" cmake
tool_info "Ninja" ninja
tool_info "Clang" clang
tool_info "GCC" gcc
tool_info ".NET" dotnet
tool_info "Docker" docker
echo '```'

echo
echo "## Reverse-engineering / game tools"
echo
echo '```text'
tool_info "Ghidra" ghidraRun
tool_info "Radare2" r2
tool_info "Rizin" rizin
tool_info "JADX" jadx
tool_info "ILSpy CLI" ilspycmd
tool_info "Wine" wine
tool_info "SteamCMD" steamcmd
echo '```'

echo
echo "## Common game locations"
echo
echo '```text'

for dir in \
  "$HOME/Library/Application Support/Steam/steamapps/common" \
  "$HOME/.steam/steam/steamapps/common" \
  "$HOME/.local/share/Steam/steamapps/common" \
  "$HOME/Games" \
  "$HOME/Documents/Games" \
  "$HOME/Documents/Decomps"
do
  if [[ -d "$dir" ]]; then
    echo "FOUND: $dir"
  fi
done

echo '```'

echo
echo "## Project-specific information"
echo
echo '```text'
echo "Game A:"
echo "Game A binary/install location:"
echo "Game A platform:"
echo "Game A mod loader / emulator:"
echo
echo "Game B:"
echo "Game B binary/install location:"
echo "Game B platform:"
echo "Game B mod loader / emulator:"
echo
echo "Goal: passthrough / rewrite / recomp / unsure"
echo "Existing source/decomp/recomp project:"
echo "Constraints:"
echo "First milestone:"
echo '```'

echo
echo "Survey complete. No files or system settings were modified."