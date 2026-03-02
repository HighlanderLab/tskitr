#!/usr/bin/env sh
set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <tool> [args...]" >&2
  exit 2
fi

tool="$1"
shift

if command -v "$tool" >/dev/null 2>&1; then
  exec "$tool" "$@"
fi

# Follow project guidance by checking user-local bin directories.
if [ -n "${HOME:-}" ]; then
  PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"
  export PATH
  if command -v "$tool" >/dev/null 2>&1; then
    exec "$tool" "$@"
  fi
fi

# As a last resort, query the user's login shell PATH.
if [ -n "${SHELL:-}" ] && [ -x "${SHELL:-}" ]; then
  resolved="$("${SHELL}" -lc "command -v \"$tool\"" 2>/dev/null || true)"
  if [ -n "$resolved" ] && [ -x "$resolved" ]; then
    exec "$resolved" "$@"
  fi
fi

echo "Executable '$tool' not found on PATH." >&2
echo "Install '$tool' and ensure your shell PATH exports it." >&2
exit 3
