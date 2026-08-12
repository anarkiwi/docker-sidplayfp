# docker-sidplayfp

[sidplayfp](https://github.com/libsidplayfp/sidplayfp) C64 SID player as a container image.

Image versions match the upstream sidplayfp release: image `v3.2.0` contains sidplayfp
`v3.2.0`. libsidplayfp and libresidfp version independently and are pinned separately in the
Dockerfile.

## Use

    docker run --rm -u $(id -u):$(id -g) -v $PWD:/work -w /work \
      anarkiwi/sidplayfp:latest -t30 -w/work/out /work/tune.sid

The entrypoint is `sidplayfp`, so arguments are passed straight through. Tags: `vX.Y.Z`,
`X.Y.Z`, `latest`. linux/amd64.

## Test

    docker build -t sidplayfp:test .
    tests/smoke.sh sidplayfp:test

`tests/smoke.sh` renders an original generated PSID and asserts the output is not silent,
which catches a player built without a SID engine. See [docs/releasing.md](docs/releasing.md)
for the release and upstream tracking workflows.
