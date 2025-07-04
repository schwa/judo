#!/usr/bin/env sh

# Set default repository path if not provided
REPO_PATH=${REPO_PATH:-/tmp/fake-repo}
COMMIT_COUNT=${COMMIT_COUNT:-2}

# Exit immediately if a command exits with a non-zero status
set -e

# Clean up and prepare the repository
rm -rf "$REPO_PATH"
mkdir -p "$REPO_PATH"
cd "$REPO_PATH"
git init --quiet
jj git init --quiet --colocate

# Create initial commits
for i in $(seq 1 $COMMIT_COUNT); do
    echo "File $i Content" > "file_$i.txt"
    jj commit --quiet -m "Fake Commit A_$i"
done

jj new --quiet zz

# Create additional commits
for i in $(seq 1 $COMMIT_COUNT); do
    echo "File $i Content" > "file_$i.txt"
    jj commit --quiet -m "Fake Commit B_$i"
done

# Merge branches
jj new --quiet "description(\"A_${COMMIT_COUNT}\")" "description(\"B_${COMMIT_COUNT}\")"
jj describe --quiet -m "Merged A_${COMMIT_COUNT} and B_${COMMIT_COUNT}"

jj new --quiet "description(\"Merged\")" -m "Fork F1"
jj new --quiet "description(\"Merged\")" -m "Fork F2"

# Add some bookmarks
jj bookmark create --quiet -r "description(\"A_1\")" "Bookmark_1"
jj bookmark create --quiet -r "description(\"B_1\")" "Bookmark_2"


# Display the log
jj log --no-pager -T "change_id.short(4)"

# Output the repository path
echo "Demo repository created at ${REPO_PATH}"
