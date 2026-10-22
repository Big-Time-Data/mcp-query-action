#!/bin/sh
# Install mcpq from a release and check its checksum. POSIX sh: GitLab
# images often have no bash.
#
#   curl -fsSLO https://github.com/Big-Time-Data/homebrew-tools/releases/latest/download/install.sh
#   sh install.sh
#
# MCPQ_VERSION        latest (default), vX.Y.Z, or a major such as v0
# MCPQ_INSTALL_DIR    default /usr/local/bin when it is writable, else ~/.local/bin
# MCPQ_RELEASE_REPO   default Big-Time-Data/homebrew-tools
# GITHUB_TOKEN        optional; raises the API rate limit for a major version
set -eu

repo=${MCPQ_RELEASE_REPO:-Big-Time-Data/homebrew-tools}
version=${MCPQ_VERSION:-latest}

die() {
  echo "install.sh: $*" >&2
  exit 1
}

case $(uname -s) in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  *) die "no mcpq build for $(uname -s); download one from https://github.com/$repo/releases" ;;
esac
case $(uname -m) in
  x86_64 | amd64) arch=amd64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *) die "no mcpq build for $(uname -m)" ;;
esac

if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL --retry 3 ${2:+-H "Authorization: Bearer $2"} -o "$1" "$3"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -q ${2:+--header="Authorization: Bearer $2"} -O "$1" "$3"; }
else
  die "install curl or wget"
fi

# A major version is the newest release with that prefix. The API lists
# the newest release first.
case $version in
  latest | v*.*.*) ;;
  v[0-9]*)
    list=$(mktemp)
    fetch "$list" "${GITHUB_TOKEN:-}" "https://api.github.com/repos/$repo/releases?per_page=100" ||
      die "list the releases of $repo"
    tag=$(sed -n 's/.*"tag_name": *"\('"$version"'\.[^"]*\)".*/\1/p' "$list" | head -n 1)
    rm -f "$list"
    [ -n "$tag" ] || die "no release of $repo matches $version"
    version=$tag
    ;;
  *) die "MCPQ_VERSION must be latest, vX.Y.Z, or a major such as v0; got $version" ;;
esac

if [ "$version" = latest ]; then
  base="https://github.com/$repo/releases/latest/download"
else
  base="https://github.com/$repo/releases/download/$version"
fi

dir=${MCPQ_INSTALL_DIR:-}
if [ -z "$dir" ]; then
  if [ -w /usr/local/bin ]; then dir=/usr/local/bin; else dir=$HOME/.local/bin; fi
fi

asset=mcpq_${os}_${arch}.tar.gz
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fetch "$tmp/$asset" "" "$base/$asset" || die "download $base/$asset"
fetch "$tmp/checksums.txt" "" "$base/checksums.txt" || die "download $base/checksums.txt"

want=$(awk -v a="$asset" '$2 == a { print $1 }' "$tmp/checksums.txt")
[ -n "$want" ] || die "checksums.txt has no line for $asset"
if command -v sha256sum >/dev/null 2>&1; then
  got=$(sha256sum "$tmp/$asset" | awk '{ print $1 }')
else
  got=$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')
fi
[ "$got" = "$want" ] || die "checksum of $asset does not match checksums.txt"

tar -xzf "$tmp/$asset" -C "$tmp" mcpq
mkdir -p "$dir"
cp "$tmp/mcpq" "$dir/mcpq.new"
chmod 0755 "$dir/mcpq.new"
mv "$dir/mcpq.new" "$dir/mcpq"
echo "mcpq $version installed in $dir/mcpq"
case ":$PATH:" in
  *":$dir:"*) ;;
  *) echo "add $dir to PATH" ;;
esac
