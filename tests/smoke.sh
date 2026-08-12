#!/bin/sh
# Smoke test a sidplayfp image: tests/smoke.sh <image> [expected-version]
set -eu

image=${1:?usage: smoke.sh <image> [expected-version]}
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
pin() { sed -n "s/^ARG $1=//p" "${here}/../Dockerfile"; }
expected=${2:-$(pin SIDPLAYFP_VERSION)}

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok: $*"; }

got=$(docker run --rm --entrypoint sh "${image}" -c 'printf %s "$SIDPLAYFP_VERSION"')
[ "${got}" = "${expected}" ] || fail "image SIDPLAYFP_VERSION ${got} != ${expected}"
ok "version ${got}"

docker run --rm "${image}" --help >/dev/null 2>&1 || fail "--help failed"
ok "runs"

# libsidplayfp only warns when libresidfp is absent, yielding a player that
# cannot emulate a SID at all. Assert the engine is linked in.
docker run --rm --entrypoint sh "${image}" -c \
  'ldd /usr/local/lib/libsidplayfp.so | grep -q residfp' \
  || fail "libsidplayfp is not linked against libresidfp"
ok "libresidfp $(pin LIBRESIDFP_VERSION) linked into libsidplayfp $(pin LIBSIDPLAYFP_VERSION)"

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
"${here}/mkpsid.py" "${work}/test.sid"

out=$(docker run --rm -u "$(id -u):$(id -g)" -v "${work}:/work" -w /work \
  "${image}" -t2 -w/work/out /work/test.sid 2>&1) \
  || fail "playing a generated PSID failed: ${out}"
printf '%s' "${out}" | grep -qi 'not built in' \
  && fail "no SID emulation built in: ${out}"
[ -s "${work}/out.wav" ] || fail "no wav written"

# A silent wav is all zero samples: a player that renders nothing still writes
# a full length file, so check for actual signal rather than file size alone.
signal=$(tail -c +45 "${work}/out.wav" | tr -d '\0' | wc -c)
[ "${signal}" -gt 1000 ] \
  || fail "rendered wav is silent (${signal} non-zero bytes of audio)"
ok "rendered $(wc -c <"${work}/out.wav") byte wav, ${signal} non-zero audio bytes"

echo "PASS ${image} (${expected})"
