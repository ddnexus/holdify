#!/usr/bin/env bash

set -e

error_handler() {
  echo "An error occurred on line $1. Executing git reset."
  git reset --hard
}

trap 'error_handler $LINENO' ERR

ROOT="$(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)")"

cur=$(ruby -Ilib -rholdify -e 'puts Holdify::VERSION')
current=${cur//./\\.}
log=$(git log --format="- %s%b" "$cur"..HEAD)

echo     "Current Holdify::VERSION: $cur"
read -rp 'Enter the new version> ' ver

[[ -z $ver ]] && echo 'Missing new version!' && exit 1
num=$(echo "$ver" | grep -o '\.' | wc -l)
[[ $num == 2 ]] || (echo 'Incomplete semantic version!' && exit 1)

version=${ver//./\\.}

# Bump version in files
function bump(){
	sed -i "0,/$current/{s/$current/$version/}" "$1"
}

bump "$ROOT/lib/holdify.rb"
bump "$ROOT/minitest-holdify.gemspec"

# Update CHANGELOG
changelog=$(cat <<-LOG
	# CHANGELOG

	## Version $ver

	$log
LOG
)

CHANGELOG="$ROOT/CHANGELOG.md"
TMPFILE=$(mktemp)
awk -v l="$changelog" '{sub(/# CHANGELOG/, l); print}' "$CHANGELOG" > "$TMPFILE"
mv "$TMPFILE" "$CHANGELOG"

# Run test to check the consistency across files
SKIP_COVERAGE=true ruby -Itest test/holdify_test.rb --name  "/holdify::Version match(#|::)/"

bundle install --local

# Show diff
#  git diff -U0

# Optional commit
read -rp 'Do you want to commit the changes? (y/n)> ' input
if [[ $input = y ]] || [[ $input = Y ]]; then
  git add .
  git commit -m "Version $ver"
fi
