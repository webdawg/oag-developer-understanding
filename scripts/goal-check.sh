#!/usr/bin/env bash
# Fitness function for GOAL.md. Exit 0 only when the mission gates pass.
# Prints SCORE: <n> (higher is better). Never modifies files.
set -u
cd "$(dirname "$0")/.."

score=0
fail=0
note() { printf 'CHECK: %s\n' "$1"; }

pin_of() {
  case "$1" in
    open-agent-graph) echo "87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe" ;;
    oag-mesh) echo "9f5d89e9fcf944dc16eff61f17543e83fc6ad20c" ;;
    oag-listend) echo "aad2d9b2cc763239764fa8ba11ec7e871be00e11" ;;
    oag-collisions) echo "dfc8ca95ce9641c29dec6bebe1586936b113c883" ;;
    oag-imagination-random-data-compute) echo "7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29" ;;
    data-roads) echo "b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e" ;;
  esac
}
dir_of() {
  case "$1" in
    open-agent-graph) echo "/home/webdawg/DATA/CODE/rust-ai" ;;
    oag-mesh) echo "/home/webdawg/DATA/CODE/oag-mesh" ;;
    oag-listend) echo "/home/webdawg/DATA/CODE/oag-listend" ;;
    oag-collisions) echo "/home/webdawg/DATA/CODE/oag-collisions" ;;
    oag-imagination-random-data-compute) echo "/home/webdawg/DATA/CODE/oag-imagination-random-data-compute" ;;
    data-roads) echo "/tmp/oag-pins/data-roads" ;;
  esac
}

repos="open-agent-graph oag-mesh oag-listend oag-collisions oag-imagination-random-data-compute data-roads"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for repo in $repos; do
  pin=$(pin_of "$repo")
  dir=$(dir_of "$repo")
  if ! git -C "$dir" cat-file -e "${pin}^{commit}" 2>/dev/null; then
    note "missing pin $repo $pin in $dir"
    fail=1
    continue
  fi
  git -C "$dir" ls-tree -r --name-only "$pin" | awk '
    $0 ~ /(^|\/)target\// { next }
    $0 ~ /Cargo\.lock$/ { next }
    $0 ~ /(^|\/)LICENSE$/ { next }
    $0 ~ /\.rs$/ || $0 ~ /\.sql$/ || $0 ~ /\.md$/ || $0 ~ /(^|\/)Cargo\.toml$/ { print }
  ' | sed "s|^|${repo}:|" | sort -u > "$tmp/${repo}.txt"
  count=$(wc -l < "$tmp/${repo}.txt")
  score=$((score + count))
  if [ ! -f "specs/inventory/${repo}.txt" ]; then
    note "missing specs/inventory/${repo}.txt ($count paths)"
    fail=1
    continue
  fi
  if ! cmp -s "specs/inventory/${repo}.txt" "$tmp/${repo}.txt"; then
    note "inventory drift specs/inventory/${repo}.txt"
    fail=1
  else
    score=$((score + 5))
  fi
done
cat "$tmp"/*.txt 2>/dev/null | sort -u > "$tmp/all.txt" || true

if [ ! -f specs/coverage.md ]; then
  note "missing specs/coverage.md"
  fail=1
else
  awk -F'|' 'NF>=5 && $2 ~ /:/ {
    path=$2; status=$3; evidence=$4; reason=$5
    gsub(/^[ \t]+|[ \t]+$/, "", path)
    gsub(/^[ \t]+|[ \t]+$/, "", status)
    gsub(/^[ \t]+|[ \t]+$/, "", evidence)
    gsub(/^[ \t]+|[ \t]+$/, "", reason)
    if (path=="Path") next
    print path "\t" status "\t" evidence "\t" reason
  }' specs/coverage.md > "$tmp/coverage.tsv"
  score=$((score + $(wc -l < "$tmp/coverage.tsv")))
  if [ -s "$tmp/all.txt" ]; then
    cut -f1 "$tmp/coverage.tsv" | sort -u > "$tmp/covpaths.txt"
    missing=$(comm -23 "$tmp/all.txt" "$tmp/covpaths.txt" | wc -l)
    extra=$(comm -13 "$tmp/all.txt" "$tmp/covpaths.txt" | wc -l)
    if [ "$missing" -ne 0 ] || [ "$extra" -ne 0 ]; then
      note "coverage path mismatch missing=$missing extra=$extra"
      fail=1
    fi
  fi
  unreviewed=$(awk -F'\t' '$2=="unreviewed"{c++} END{print c+0}' "$tmp/coverage.tsv")
  blocked=$(awk -F'\t' '$2=="unknown-blocked"{c++} END{print c+0}' "$tmp/coverage.tsv")
  badstatus=$(awk -F'\t' '$2!="explained" && $2!="partial" && $2!="out-of-scope" && $2!="unknown-blocked" && $2!="unreviewed"{c++} END{print c+0}' "$tmp/coverage.tsv")
  [ "$unreviewed" -eq 0 ] || { note "unreviewed=$unreviewed"; fail=1; }
  [ "$blocked" -le 8 ] || { note "unknown-blocked=$blocked exceeds 8"; fail=1; }
  [ "$badstatus" -eq 0 ] || { note "bad coverage status rows=$badstatus"; fail=1; }
  dup_reasons=$(awk -F'\t' '$2=="out-of-scope"{print $4}' "$tmp/coverage.tsv" | sort | uniq -c | awk '$1>5{c++} END{print c+0}')
  [ "$dup_reasons" -eq 0 ] || { note "out-of-scope reason reused >5 times"; fail=1; }
  while IFS=$'\t' read -r path status evidence reason; do
    case "$status" in
      explained|partial)
        ids=$(printf '%s' "$evidence" | grep -oE '[0-9]{4}' || true)
        [ -n "$ids" ] || { note "no finding id for $path"; fail=1; continue; }
        hit=0
        rel=${path#*:}
        for id in $ids; do
          f=$(ls findings/"$id"-*.md 2>/dev/null | head -1 || true)
          if [ -n "$f" ] && grep -F -q "$rel" "$f"; then hit=1; score=$((score + 10)); break; fi
        done
        [ "$hit" -eq 1 ] || { note "finding does not cite $path"; fail=1; }
        ;;
      unknown-blocked)
        [ "${#reason}" -ge 40 ] || { note "short unknown-blocked reason for $path"; fail=1; }
        ;;
      out-of-scope)
        [ "${#reason}" -ge 20 ] || { note "short out-of-scope reason for $path"; fail=1; }
        ;;
    esac
  done < "$tmp/coverage.tsv"
fi

if [ -d findings ]; then
  find findings -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -printf '%f\n' | sort > "$tmp/findings.txt"
  n=$(wc -l < "$tmp/findings.txt")
  score=$((score + n * 2))
  expect=1
  highest=0
  while read -r name; do
    num=$((10#${name%%-*}))
    if [ "$num" -ne "$expect" ]; then
      note "finding number gap at $name expected $(printf '%04d' "$expect")"
      fail=1
      break
    fi
    f="findings/$name"
    grep -q '^## Evidence' "$f" || { note "$name missing Evidence"; fail=1; }
    grep -q '^## Next investigation' "$f" || { note "$name missing Next investigation"; fail=1; }
    if [ "$num" -gt 130 ]; then
      grep -q '^## Why it matters' "$f" || { note "$name missing Why it matters"; fail=1; }
      grep -q 'Verification: source inspection only' "$f" || { note "$name missing verification line"; fail=1; }
      grep -qE '87f9e8c1|9f5d89e9|aad2d9b2|dfc8ca95|7b7dcb8e|b5cd2f4e' "$f" || { note "$name missing pin"; fail=1; }
    fi
    highest=$num
    expect=$((expect + 1))
  done < "$tmp/findings.txt"
  if [ "$highest" -gt 0 ] && ! grep -q "$(printf '%04d' "$highest")" JOURNAL.md; then
    note "JOURNAL.md does not mention finding $(printf '%04d' "$highest")"
    fail=1
  else
    score=$((score + 5))
  fi
fi

for pin in 87f9e8c1c2bc8cbfbec1c34800fbf40b2fdae6fe 9f5d89e9fcf944dc16eff61f17543e83fc6ad20c aad2d9b2cc763239764fa8ba11ec7e871be00e11 dfc8ca95ce9641c29dec6bebe1586936b113c883 7b7dcb8eae70b2df2fa1329fdb7b2dd928e76d29 b5cd2f4e8618f955eb06dd1c4d3edc7234041a7e; do
  grep -q "$pin" README.md || { note "README lost pin $pin"; fail=1; }
done
[ -f flows/connection-register.md ] || { note "missing connection register"; fail=1; }

printf 'SCORE: %s\n' "$score"
if [ "$fail" -ne 0 ]; then
  note "not complete"
  exit 1
fi
note "complete"
exit 0
