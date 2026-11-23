#!/bin/sh
# Per-user install from an immutable release catalog; no sudo, package manager,
# language toolchain or source checkout. Use --role launcher for the desk alone.
install_cortivar() (
  set -eu
  umask 077
  docs=https://raw.githubusercontent.com/Cortivar/platform-docs/main
  role=host
  version=''
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --version) version=${2:?missing version}; shift 2;;
      --role) role=${2:?missing role}; shift 2;;
      *) echo 'Usage: install.sh [--version vX.Y.Z] [--role host|launcher]' >&2; exit 2;;
    esac
  done
  case "$role" in host|launcher);; *) echo 'Unknown installation role.' >&2; exit 2;; esac
  case "$(uname -sm)" in
    'Darwin arm64') target=darwin-arm64;; 'Darwin x86_64') target=darwin-amd64;;
    'Linux x86_64') target=linux-amd64;; 'Linux aarch64'|'Linux arm64') target=linux-arm64;;
    *) echo 'Unsupported target. On Windows use install.ps1.' >&2; exit 1;;
  esac
  get() { curl --disable --fail --location --proto '=https' --proto-redir '=https' --silent --show-error --max-time 600 "$1" -o "$2"; }
  tmp=$(mktemp -d); staging=''
  trap 'rm -rf -- "$tmp"; [ -z "$staging" ] || rm -rf -- "$staging"' EXIT
  trap 'exit 1' HUP INT TERM
  if [ -z "$version" ]; then get "$docs/channels/stable" "$tmp/stable"; version=$(cat "$tmp/stable"); fi
  if [ "$version" = unpublished ]; then echo 'No tested full-platform release has been published yet.' >&2; exit 1; fi
  case "$version" in *[!0-9a-zA-Z.-]*|'') exit 2;; esac
  case "$version" in v[0-9]*);; *) exit 2;; esac
  get "$docs/versions/$version/files.tsv" "$tmp/catalog"
  fetch_asset() {
    key=$1; dest=$2
    url=$(awk -v k="$key" '$1==k{v=$3;n++}END{if(n!=1)exit 1;print v}' "$tmp/catalog") || { echo "No unique asset for $key." >&2; exit 1; }
    expected=$(awk -v k="$key" '$1==k{print $2}' "$tmp/catalog")
    case "$expected" in *[!0-9a-f]*) exit 1;; esac; [ "${#expected}" = 64 ] || exit 1
    case "$url" in https://*) ;; *) exit 1;; esac
    get "$url" "$dest"
    if command -v sha256sum >/dev/null; then actual=$(sha256sum <"$dest"); else actual=$(shasum -a 256 <"$dest"); fi
    [ "${actual%% *}" = "$expected" ] || { echo "Checksum failed: $key" >&2; exit 1; }
  }
  fetch_asset "launcher-$target" "$tmp/launcher.gz"; digest=$expected
  gzip -dc "$tmp/launcher.gz" >"$tmp/cortivar"; chmod 700 "$tmp/cortivar"
  if [ "$target" = linux-amd64 ]; then fetch_asset worker-linux-amd64 "$tmp/worker.gz"; gzip -dc "$tmp/worker.gz" >"$tmp/cortivar-host"; chmod 700 "$tmp/cortivar-host"; fi
  if [ "$role" = host ]; then
    case "$target" in linux-amd64) pkg=install-tui.sh;; *) pkg=host.zip;; esac
    fetch_asset "host-$target" "$tmp/$pkg"
  fi
  root="$HOME/.local/share/cortivar/launcher"; bin="$HOME/.local/bin"; link="$bin/cortivar"
  mkdir -p "$root/$digest" "$bin"
  if [ -e "$link" ] || [ -L "$link" ]; then
    current=$(readlink "$link") || { echo "Unmanaged $link left unchanged." >&2; exit 1; }
    id=${current#"$root"/}; id=${id%/cortivar}
    case "$id" in *[!0-9a-f]*) exit 1;; esac
    [ "${#id}" = 64 ] && [ "$current" = "$root/$id/cortivar" ] || { echo "Unmanaged $link left unchanged." >&2; exit 1; }
  fi
  staging=$(mktemp -d "$root/$digest/.staging-XXXXXXXX")
  cp "$tmp/cortivar" "$staging/cortivar"
  if [ "$target" = linux-amd64 ]; then cp "$tmp/cortivar-host" "$staging/cortivar-host"; mv -f "$staging/cortivar-host" "$root/$digest/"; fi
  mv -f "$staging/cortivar" "$root/$digest/"
  ln -s "$root/$digest/cortivar" "$staging/link"; mv -f "$staging/link" "$link"
  if [ "$role" = host ]; then "$link" install meltemia "$tmp/$pkg"; fi
  echo "Installed $version. Run: \"$link\""
)
install_cortivar "$@"
