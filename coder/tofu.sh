#!/usr/bin/env bash
# Runs OpenTofu in this context with its secrets injected for that one command.
#
#   ./tofu.sh init
#   ./tofu.sh plan
#   ./tofu.sh apply
#
# Nothing is written to disk. The static secrets (Raindrop OAuth client, Home
# Assistant token) come from Bitwarden Secrets Manager, and the Coder admin
# token is minted for this run and revoked when it exits. See README.md.
set -euo pipefail

BWS_PROJECT_NAME="${BWS_PROJECT_NAME:-Homelab-IaC}"
BWS_KEYCHAIN_SERVICE="${BWS_KEYCHAIN_SERVICE:-homelab-bws-operator}"
BWS_TOKEN_FILE="${BWS_TOKEN_FILE:-$HOME/.config/bws/operator-token}"
CODER_TOKEN_LIFETIME="${CODER_TOKEN_LIFETIME:-1h}"
REQUIRED_SECRETS="TF_VAR_raindrop_oauth_client_id TF_VAR_raindrop_oauth_client_secret TF_VAR_home_assistant_mcp_token"

die() {
  printf 'tofu.sh: %s\n' "$*" >&2
  exit 1
}

for cmd in bws coder jq tofu; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd is not installed"
done
[ -n "${AWS_ACCESS_KEY_ID:-}" ] && [ -n "${AWS_SECRET_ACCESS_KEY:-}" ] ||
  die "the Storj state credentials are not set; run: set -a && source ~/.homelab-opentofu.env && set +a"

cd "$(dirname "${BASH_SOURCE[0]}")"

# The access token comes from, in order: $BWS_ACCESS_TOKEN, the macOS Keychain,
# or a 0600 file. Each computer holds its own token, so a lost machine costs one
# revocation.
load_bws_token() {
  [ -n "${BWS_ACCESS_TOKEN:-}" ] && return 0
  local t="" perms
  if [ "$(uname -s)" = Darwin ] && command -v security >/dev/null 2>&1; then
    t="$(security find-generic-password -s "$BWS_KEYCHAIN_SERVICE" -w 2>/dev/null || true)"
  fi
  if [ -z "$t" ] && [ -r "$BWS_TOKEN_FILE" ]; then
    perms="$(stat -c '%a' "$BWS_TOKEN_FILE" 2>/dev/null || stat -f '%Lp' "$BWS_TOKEN_FILE")"
    case "$perms" in
      600 | 400) ;;
      *) die "$BWS_TOKEN_FILE has mode $perms; run: chmod 600 $BWS_TOKEN_FILE" ;;
    esac
    t="$(tr -d '[:space:]' <"$BWS_TOKEN_FILE")"
  fi
  [ -n "$t" ] || die "no Bitwarden Secrets Manager access token found (see README.md)"
  export BWS_ACCESS_TOKEN="$t"
}

resolve_project_id() {
  if [ -n "${BWS_PROJECT_ID:-}" ]; then
    printf '%s' "$BWS_PROJECT_ID"
    return 0
  fi
  local ids
  ids="$(bws project list -o json | jq -r --arg n "$BWS_PROJECT_NAME" '.[] | select(.name == $n) | .id')" ||
    die "could not list projects; is the access token valid?"
  [ -n "$ids" ] || die "no project named '$BWS_PROJECT_NAME' is visible to this machine account"
  [ "$(printf '%s\n' "$ids" | wc -l | tr -d ' ')" = 1 ] ||
    die "more than one project is named '$BWS_PROJECT_NAME'; set BWS_PROJECT_ID"
  printf '%s' "$ids"
}

load_bws_token
project_id="$(resolve_project_id)"

# Fail early, and by name only, if a secret is missing. Values are never printed.
present="$(bws secret list "$project_id" -o json | jq -r '.[].key')" ||
  die "could not read the secrets in '$BWS_PROJECT_NAME'"
missing=""
for k in $REQUIRED_SECRETS; do
  printf '%s\n' "$present" | grep -qx "$k" || missing="$missing $k"
done
[ -z "$missing" ] || die "missing from '$BWS_PROJECT_NAME':$missing"

# A short-lived Coder admin token for this run only. If the revoke below fails,
# the token still expires on its own.
coder whoami >/dev/null 2>&1 || die "not logged in to Coder; run: coder login"
tok_name="opentofu-$(date +%Y%m%d-%H%M%S)-$$"
TF_VAR_coder_session_token="$(coder tokens create --name "$tok_name" --lifetime "$CODER_TOKEN_LIFETIME" 2>/dev/null)" ||
  die "could not create a Coder token; the logged-in user needs to be an admin"
export TF_VAR_coder_session_token
trap 'coder tokens remove "$tok_name" >/dev/null 2>&1 || true' EXIT

# tofu and the providers it loads never need the Bitwarden token. Current `bws`
# already removes it from the child's environment, but unset it here too so this
# doesn't depend on the installed version. `bws run` executes `sh -c "<command>"`
# and the environment is otherwise inherited, so the state credentials (AWS_*)
# and PATH still reach tofu.
cmd="env -u BWS_ACCESS_TOKEN $(printf '%q ' tofu "$@")"
bws run --project-id "$project_id" -- "$cmd"
