#!/usr/bin/env bash

# Change the version information in src/spat-version.ads

if [ "$#" -ne 1 ]; then
    echo "No or more than one version number given. Please provide exactly one."
    echo "Here is a list of existing tags:"
    (echo "TAG|DATE" && git tag --sort="creatordate" --format="%(refname:short)|%(authordate:iso8601)") | column -s\| -t -x
    exit 1
fi

VERSION_NUMBER=$1

# 
confirm()
{
    echo "$1"
    read -p "Ctrl-C to abort, ENTER to continue..." || exit 255
}

# Validate input version number.

# Check format
if [ -z `echo $VERSION_NUMBER | grep -P '^(\d+\.)+(\d+\.)+(\d+)+([-][a-z]*)?$'` ]; then
    echo "Version number \"${VERSION_NUMBER}\" is not in format d.d.d[-suffix]"
    exit 2
fi

# Check if it's unique
TAGS=`git tag | grep -P "^v${VERSION_NUMBER}$"`

if [ -n "${TAGS}" ]; then
    echo "Version number \"${VERSION_NUMBER}\" has already been used."
    exit 3
fi

echo "Latest version number used was \"`git tag --sort=\"creatordate\" | tail -1`\", new one is \"v${VERSION_NUMBER}\"."
confirm "Does that look fine to you?"

# Patch file with new version number
VFILE="src/spat-version.ads"

sed 's/^\(\ \+Number\ \+:\ \+constant\ \+String\ \+:=\ \+\"\)\([0-9a-z.-]*\)\(\";\)/\1'${VERSION_NUMBER}'\3/' $VFILE > $VFILE.new || (echo "Could not patch file. Are you in the root directory?"; exit 4)

cat $VFILE.new || (echo "Could not display file. That's odd."; exit 5)
confirm "This would be the new version file."

# Overwrite target file.
mv $VFILE.new $VFILE || (echo "Failure to move file to final location!"; exit 6)

# Recompile
gprbuild -f -P spat.gpr || (echo "Compilation failed!"; exit 7)

# TODO: Run executable and check that it reports the expected version.

confirm "Last chance. Do you really want me to commit and tag \"v${VERSION_NUMBER}\"?"

# Compilation successful, add the file and commit, and then tag the version
git commit --dry-run $VFILE -m "* Automated tagging of ${VERSION_NUMBER} version."
confirm "Does the dry run look ok to you?"

git commit $VFILE -m "* Automated tagging of ${VERSION_NUMBER} version." || exit 4
git tag v${VERSION_NUMBER} || exit 5

echo "Version \"v${VERSION_NUMBER}\" tagged. You may want to do 'git push --tags', though."
