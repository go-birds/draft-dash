#!/usr/bin/env bash
set -euo pipefail

mount_path="/"
flutter_args=()

while (($#)); do
  case "$1" in
    --mount-path)
      if (($# < 2)); then
        echo "--mount-path requires / or a path such as /draft/" >&2
        exit 64
      fi
      mount_path="$2"
      shift 2
      ;;
    *)
      flutter_args+=("$1")
      shift
      ;;
  esac
done

if [[ "$mount_path" != /* || "$mount_path" != */ ]]; then
  echo "--mount-path must start and end with /" >&2
  exit 64
fi

if ((${#flutter_args[@]})); then
  flutter build web --release --base-href "$mount_path" "${flutter_args[@]}"
else
  flutter build web --release --base-href "$mount_path"
fi

# Flutter only copies recognized web-runner files. Stage Cloudflare Pages'
# underscore-prefixed control files after a successful build.
if [[ "$mount_path" == "/" ]]; then
  cp web/_headers web/_redirects build/web/
  echo "Root-host bundle: build/web"
  exit 0
fi

# A path-mounted app is a fragment for the existing root site's pipeline. Its
# assets live under the mount path while Cloudflare control files stay at the
# hosting output root. Never deploy this fragment over an unrelated root site.
mount_name="${mount_path#/}"
mount_name="${mount_name%/}"
site_output="build/site"
rm -rf "$site_output"
mkdir -p "$site_output/$mount_name"
cp -R build/web/. "$site_output/$mount_name/"
sed "s|^/|${mount_path}|" web/_headers >"$site_output/_headers"
sed \
  -e "s|^/\*|${mount_path}*|" \
  -e "s| /index.html| ${mount_path}index.html|" \
  web/_redirects >"$site_output/_redirects"
echo "Path-mount fragment: $site_output (merge into the root site's output)"
