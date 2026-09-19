"""Generate Chemistry's plugin: one quest with one script attached, nothing else.

Copied from Rapport's tools/make_esp.py so this repository can rebuild its own esp
without Rapport's source present. The shape is not from documentation -- it was read
out of a real working record: AAF.esm's AAF_MainQuest carries a VMAD whose QUST
form, with no fragments, has no trailing fragment section, and parsing it end to end
consumes every byte. So: version 6, object format 2, one script, no properties.

The Creation Kit is the usual way to make this and cannot be driven headlessly. This
plugin is small enough to write directly.

    python tools/make_esp.py data/Chemistry.esp

Verify what came out with tools/read_esp.py.
"""

import struct
import sys

SCRIPT_NAME = 'Chemistry:Autonomy'
QUEST_EDID = 'ChemistryAutonomyQuest'
AUTHOR = 'Chemistry'
MASTER = 'Fallout4.esm'

# The first object id a new plugin may use; below 0x800 is reserved.
QUEST_FORMID = 0x01000800

# The only thing Rapport ever has to ask the player. AAF's main quest being
# stopped is the one failure this framework must not fix on its own: it may mean
# AAF is on its way out of this save, which nothing in the plugin can see and the
# player can. Every other AAF failure is repaired silently.
#
# ASCII only -- zstring() encodes as ascii and a smart quote is enough to fail it.


def field(sig, data):
    if len(data) > 0xFFFF:
        raise ValueError('{} too large for a plain field'.format(sig))
    return sig.encode('ascii') + struct.pack('<H', len(data)) + data


def zstring(text):
    return text.encode('ascii') + b'\0'


def wstring(text):
    raw = text.encode('ascii')
    return struct.pack('<H', len(raw)) + raw


def record(sig, form_id, fields_blob, flags=0):
    # 24-byte record header: sig, dataSize, flags, formID, VCS1, formVersion, VCS2
    return (sig.encode('ascii')
            + struct.pack('<III', len(fields_blob), flags, form_id)
            + struct.pack('<IHH', 0, 131, 0)
            + fields_blob)


def group(label, records_blob):
    size = 24 + len(records_blob)
    return (b'GRUP'
            + struct.pack('<I', size)
            + label.encode('ascii')
            + struct.pack('<I', 0)          # top-level group
            + struct.pack('<IHH', 0, 0, 0)
            + records_blob)


def build(script_name, quest_edid):
    # ---- the quest ----------------------------------------------------------
    vmad = struct.pack('<hhH', 6, 2, 1)        # version, object format, script count
    vmad += wstring(script_name)
    vmad += struct.pack('<B', 0)               # status: local
    vmad += struct.pack('<H', 0)               # no properties

    # DNAM copied from AAF_MainQuest, a quest that starts itself and runs:
    # flags 0x0011 (start game enabled), priority 100. Copying a known-good
    # record beats inventing twelve bytes of flags.
    dnam = bytes.fromhex('11 00 64 67 00 00 00 00 00 00 00 00'.replace(' ', ''))

    quest = field('EDID', zstring(quest_edid))
    quest += field('VMAD', vmad)
    quest += field('DNAM', dnam)
    quest += field('NEXT', b'')                # alias section marker, empty

    quest_record = record('QUST', QUEST_FORMID, quest)
    quest_group = group('QUST', quest_record)

    # One quest and nothing else. Chemistry asks the player nothing: every choice
    # it makes is about two NPCs who are not the player, so there is no message
    # record here and no reason for one.
    next_object = QUEST_FORMID + 1

    # ---- the header ---------------------------------------------------------
    hedr = struct.pack('<fiI', 1.0, 1, next_object)
    header_fields = field('HEDR', hedr)
    header_fields += field('CNAM', zstring(AUTHOR))
    header_fields += field('MAST', zstring(MASTER))
    header_fields += field('DATA', struct.pack('<Q', 0))

    header = record('TES4', 0, header_fields)
    return header + quest_group


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    script_name = sys.argv[2] if len(sys.argv) > 2 else SCRIPT_NAME
    quest_edid = sys.argv[3] if len(sys.argv) > 3 else QUEST_EDID

    blob = build(script_name, quest_edid)
    with open(sys.argv[1], 'wb') as fh:
        fh.write(blob)
    print('wrote {} ({} bytes)'.format(sys.argv[1], len(blob)))
    print('  quest  {} formID {:08X}'.format(quest_edid, QUEST_FORMID))
    print('  script {}'.format(script_name))
    print('  master {}'.format(MASTER))
    return 0


if __name__ == '__main__':
    sys.exit(main())
