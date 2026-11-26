#!/usr/bin/env bash
# Endless fitness function. Always exits 1. Prints SCORE: <n>.
# Higher means revisions are fetched and explained HEADs are closer to origin.
set -u
cd "$(dirname "$0")/.."

score=0
note() { printf 'CHECK: %s\n' "$1"; }

if [ ! -f specs/revisions.md ]; then
  note "missing specs/revisions.md"
  printf 'SCORE: 0\n'
  note "endless; do not stop"
  exit 1
fi

awk -F'|' 'NF>=6 && $2 ~ /[a-z]/ && $2 !~ /Repository/ && $2 !~ /---/ {
  for (i=2;i<=6;i++) gsub(/^[ \t]+|[ \t]+$/, "", $i)
  print $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6
}' specs/revisions.md > /tmp/oag-revisions.tsv

rows=0
while IFS=$'\t' read -r repo branch dir latest explained; do
  rows=$((rows + 1))
  if [ ! -d "$dir/.git" ] && [ ! -f "$dir/.git" ]; then
    note "missing git dir for $repo ($dir)"
    score=$((score - 100))
    continue
  fi
  origin=$(git -C "$dir" rev-parse "origin/${branch}" 2>/dev/null || true)
  if [ -z "$origin" ]; then
    note "no origin/${branch} for $repo"
    score=$((score - 100))
    continue
  fi
  if [ "$origin" = "$latest" ]; then
    score=$((score + 200))
  else
    note "$repo latest cell is stale ($latest != $origin)"
    score=$((score - 150))
  fi
  if [ "$explained" = "$origin" ]; then
    score=$((score + 400))
  elif git -C "$dir" merge-base --is-ancestor "$explained" "$origin" 2>/dev/null; then
    behind=$(git -C "$dir" rev-list --count "${explained}..${origin}")
    note "$repo explained is $behind commits behind origin/${branch}"
    score=$((score + 300 - behind))
  else
    note "$repo explained $explained is not an ancestor of origin/${branch}"
    score=$((score - 200))
  fi
done < /tmp/oag-revisions.tsv

if [ "$rows" -ne 6 ]; then
  note "expected 6 revision rows, found $rows"
  score=$((score - 100))
fi

if [ -d findings ]; then
  find findings -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -printf '%f\n' | sort > /tmp/oag-findings.txt
  n=$(wc -l < /tmp/oag-findings.txt)
  score=$((score + n))
  expect=1
  highest=0
  while read -r name; do
    num=$((10#${name%%-*}))
    if [ "$num" -ne "$expect" ]; then
      note "finding gap at $name"
      score=$((score - 50))
      break
    fi
    if [ "$num" -gt 130 ]; then
      f="findings/$name"
      grep -q '^## Evidence' "$f" || score=$((score - 10))
      grep -q '^## Next investigation' "$f" || score=$((score - 10))
      grep -q '^## Why it matters' "$f" || score=$((score - 10))
      grep -q 'Verification: source inspection only' "$f" || score=$((score - 10))
    fi
    highest=$num
    expect=$((expect + 1))
  done < /tmp/oag-findings.txt
  if [ "$highest" -gt 0 ] && ! grep -q "$(printf '%04d' "$highest")" JOURNAL.md; then
    note "JOURNAL.md missing finding $(printf '%04d' "$highest")"
    score=$((score - 30))
  fi
fi

[ -f flows/connection-register.md ] || score=$((score - 20))
grep -q 'specs/revisions.md' README.md || note "README does not point at specs/revisions.md"

printf 'SCORE: %s\n' "$score"
note "endless; do not stop"
exit 1
