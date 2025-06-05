#!/usr/bin/env sh

REPO_PATH=/tmp/fake-repo
rm -rf "$REPO_PATH"
mkdir -p "$REPO_PATH"
cd "$REPO_PATH"
git init --quiet
jj git init --quiet --colocate

for i in {1..5}; do
    echo "File $i Content" > "file_$i.txt"
    jj commit --quiet -m "Fake Commit A_$i"
done

jj new --quiet zz

for i in {1..5}; do
    echo "File $i Content" > "file_$i.txt"
    jj commit --quiet -m "Fake Commit B_$i"
done

jj new --quiet 'description("A_5")' 'description("B_5")'
jj describe --quiet -m "Merged A_5 and B_5"

jj log --no-pager

echo "Demo repository created at $REPO_PATH"
