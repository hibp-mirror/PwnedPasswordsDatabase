#!/bin/sh
# test.sh — verify the HIBP Pwned Passwords API served by ./Caddyfile.
# Run from the project root (where ./Caddyfile and ./pwnedpasswords/ live)
# with caddy running: caddy run --config Caddyfile
set -Cue

g_base_url="${HIBP_BASE_URL:-https://hibp.localhost}"

# Caddy's internal CA: if not in the system trust store (e.g. Linux),
# point curl at it. (Override with CURL_CA_BUNDLE if your setup differs.)
if test -z "${CURL_CA_BUNDLE:-}"; then
	for b_ca in "$HOME/.local/share/caddy/pki/authorities/local/root.crt" \
			    "$HOME/.local/share/caddy/pki/authorities/local/root/root.crt" \
			    "$HOME/Library/Application Support/Caddy/pki/authorities/local/root.crt"; do
		if test -f "$b_ca"; then
			export CURL_CA_BUNDLE="$b_ca"
			break
		fi
	done
fi
g_range_path='/range/5BAA6'
g_file_rel='pwnedpasswords/5B/5BAA6'

b_pass=0
b_fail=0

fn_get() (
	a_path=$1
	# curl prints 000 via --write-out on connect failures; mask the exit
	# status or set -e would abort the whole suite.
	curl --silent --output /dev/null --write-out '%{http_code}' -- "$g_base_url${a_path}" || true
)

fn_get_path_as_is() (
	a_path=$1
	curl --silent --path-as-is --output /dev/null --write-out '%{http_code}' -- "$g_base_url${a_path}" || true
)

fn_check() {
	a_desc=$1
	a_got=$2
	a_want=$3
	if test "$a_got" = "$a_want"; then
		b_pass=$((b_pass + 1))
		printf 'PASS %s\n' "$a_desc"
	else
		b_fail=$((b_fail + 1))
		printf 'FAIL %s: got %s want %s\n' "$a_desc" "$a_got" "$a_want" >&2
	fi
}

fn_body_bytes() (
	a_path=$1
	curl --silent --output /dev/null --write-out '%{size_download}' -- "$g_base_url${a_path}" || true
)

fn_encoding() (
	a_encoding=$1
	b_headers=$(curl --silent -D - --output /dev/null --header "Accept-Encoding: $a_encoding" -- "$g_base_url${g_range_path}")
	case $b_headers in
		*"content-encoding: ${a_encoding}"*) printf 'yes' ;;
		*) printf 'no' ;;
	esac
)

# --- 200: official API and raw tree ---
b_status=$(fn_get "$g_range_path")
fn_check 'GET /range/5BAA6 returns 200' "$b_status" 200

b_status=$(fn_get '/range/00000')
fn_check 'GET /range/00000 returns 200' "$b_status" 200

b_status=$(fn_get '/pwnedpasswords/5B/5BAA6')
fn_check 'GET /pwnedpasswords/5B/5BAA6 (raw) returns 200' "$b_status" 200

b_bytes=$(fn_body_bytes "$g_range_path")
b_file_bytes=$(($(wc -c < "$g_file_rel")))
fn_check 'served byte count matches ./pwnedpasswords/5B/5BAA6' "$b_bytes" "$b_file_bytes"

# --- 404: malformed range requests and unmatched paths ---
b_status=$(fn_get '/range/5BAA')
fn_check 'GET /range/5BAA (4 chars) returns 404' "$b_status" 404

b_status=$(fn_get '/range/5BAA6A')
fn_check 'GET /range/5BAA6A (6 chars) returns 404' "$b_status" 404

b_status=$(fn_get '/range/5BZZ1')
fn_check 'GET /range/5BZZ1 (non-hex) returns 404' "$b_status" 404

b_status=$(fn_get '/range/5BZZ0')
fn_check 'GET /range/5BZZ0 (missing file) returns 404' "$b_status" 404

b_status=$(fn_get '/')
fn_check 'GET / serves index.html' "$b_status" 200

b_status=$(fn_get '/index.html')
fn_check 'GET /index.html returns 200' "$b_status" 200

b_status=$(fn_get '/hibp-check.js')
fn_check 'GET /hibp-check.js returns 200' "$b_status" 200

b_status=$(fn_get '/range/')
fn_check 'GET /range/ returns 404' "$b_status" 404

b_status=$(fn_get '/pwnedpasswords/')
fn_check 'GET /pwnedpasswords/ returns 404' "$b_status" 404

b_status=$(fn_get_path_as_is '/pwnedpasswords/../Caddyfile')
fn_check 'GET /pwnedpasswords/../Caddyfile (traversal) returns 404' "$b_status" 404

# --- encodings: gzip + zstd, no brotli ---
b_zstd=$(fn_encoding 'zstd')
fn_check 'zstd content-encoding is offered' "$b_zstd" yes

b_gzip=$(fn_encoding 'gzip')
fn_check 'gzip content-encoding is offered' "$b_gzip" yes

# --- integrity: full line count of the served range file ---
b_served_lines=$(curl --silent -- "$g_base_url${g_range_path}" | wc -l)
b_served_lines=$((b_served_lines))
b_source_lines=$(($(wc -l < "$g_file_rel")))
fn_check 'served line count matches source file' "$b_served_lines" "$b_source_lines"

printf '\n%d passed, %d failed\n' "$b_pass" "$b_fail"
if test "$b_fail" -gt 0; then
	exit 1
fi
