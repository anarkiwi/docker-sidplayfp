#!/usr/bin/env python3
"""Generate a minimal original PSID for smoke testing (no third party tunes).

The tune gates a triangle voice so the rendered output is audibly non-silent:
a player built without a SID engine either errors out or writes silence.
"""

import struct
import sys

LOAD = 0x1000
# init: volume, envelope, frequency, then gate a triangle voice.
INIT_CODE = bytes(
    (
        0xA9, 0x0F, 0x8D, 0x18, 0xD4,  # lda #$0f  sta $d418  volume
        0xA9, 0x21, 0x8D, 0x05, 0xD4,  # lda #$21  sta $d405  attack/decay
        0xA9, 0xF0, 0x8D, 0x06, 0xD4,  # lda #$f0  sta $d406  sustain/release
        0xA9, 0x20, 0x8D, 0x00, 0xD4,  # lda #$20  sta $d400  freq lo
        0xA9, 0x10, 0x8D, 0x01, 0xD4,  # lda #$10  sta $d401  freq hi
        0xA9, 0x11, 0x8D, 0x04, 0xD4,  # lda #$11  sta $d404  triangle + gate
        0x60,  # rts
    )
)
PLAY_CODE = bytes((0x60,))  # rts
INIT = LOAD
PLAY = LOAD + len(INIT_CODE)


def psid():
    header = struct.pack(
        ">4sHHHHHHHI32s32s32sHBBBB",
        b"PSID",
        2,  # version
        0x7C,  # data offset
        0,  # load address taken from the data prefix
        INIT,
        PLAY,
        1,  # songs
        1,  # start song
        0,  # speed
        b"smoke test",
        b"docker-sidplayfp",
        b"2026",
        0,  # flags
        0,  # start page
        0,  # page length
        0,  # second SID address
        0,  # third SID address
    )
    return header + struct.pack("<H", LOAD) + INIT_CODE + PLAY_CODE


if __name__ == "__main__":
    with open(sys.argv[1], "wb") as f:
        f.write(psid())
