# -*- coding: utf-8 -*-
"""Extract app label from an APK without aapt: parse AndroidManifest.xml (AXML) + resources.arsc."""
import struct, zipfile, sys


def parse_string_pool(data, off):
    typ, hsz, csz = struct.unpack_from('<HHI', data, off)
    assert typ == 0x0001, hex(typ)
    strcount, stylecount, flags, strstart, stylestart = struct.unpack_from('<IIIII', data, off + 8)
    utf8 = (flags & 0x100) != 0
    offs = struct.unpack_from('<%dI' % strcount, data, off + hsz)
    base = off + strstart
    out = []
    for o in offs:
        p = base + o
        try:
            if utf8:
                n = data[p]; p += 1
                if n & 0x80:
                    p += 1
                n2 = data[p]; p += 1
                if n2 & 0x80:
                    n2 = ((n2 & 0x7f) << 8) | data[p]; p += 1
                out.append(data[p:p + n2].decode('utf-8', 'ignore'))
            else:
                n = struct.unpack_from('<H', data, p)[0]; p += 2
                if n & 0x8000:
                    n = ((n & 0x7fff) << 16) | struct.unpack_from('<H', data, p)[0]; p += 2
                out.append(data[p:p + n * 2].decode('utf-16-le', 'ignore'))
        except Exception:
            out.append('')
    return out


def chunks(data, start, end):
    p = start
    while p + 8 <= end:
        typ, hsz, size = struct.unpack_from('<HHI', data, p)
        if size < 8:
            break
        yield typ, hsz, size, p
        p += size


def manifest_label(axml):
    """Return (raw_label_string_or_None, resource_id_or_None)."""
    typ, hsz, size = struct.unpack_from('<HHI', axml, 0)
    pool = None
    for ctyp, chsz, csize, cp in chunks(axml, hsz, len(axml)):
        if ctyp == 0x0001:
            pool = parse_string_pool(axml, cp)
        elif ctyp == 0x0102:  # START_TAG
            ns, name_idx, attrStart, attrSize, attrCount = struct.unpack_from('<IIHHH', axml, cp + 16)
            tagname = pool[name_idx] if pool and name_idx < len(pool) else ''
            if tagname != 'application':
                continue
            base = cp + 16 + attrStart
            for i in range(attrCount):
                a = base + i * attrSize
                a_ns, a_name, a_raw, v_size, v_res0, v_type, v_data = struct.unpack_from('<IIIHBBI', axml, a)
                aname = pool[a_name] if pool and a_name < len(pool) else ''
                if aname == 'label':
                    raw = pool[a_raw] if (v_type == 0x03 and pool and a_raw < len(pool)) else None
                    resid = v_data if v_type == 0x01 else None
                    return raw, resid
    return None, None


def arsc_lookup(arsc, resid):
    typ, hsz, size = struct.unpack_from('<HHI', arsc, 0)
    assert typ == 0x0002, hex(typ)
    global_pool = None
    pkg_id = (resid >> 24) & 0xff
    type_id = (resid >> 16) & 0xff
    entry_id = resid & 0xffff
    for ctyp, chsz, csize, cp in chunks(arsc, hsz, len(arsc)):
        if ctyp == 0x0001:
            global_pool = parse_string_pool(arsc, cp)
    if global_pool is None:
        return None
    for ctyp, chsz, csize, cp in chunks(arsc, hsz, len(arsc)):
        if ctyp != 0x0200:
            continue
        pid = struct.unpack_from('<I', arsc, cp + 8)[0]
        if pid != pkg_id:
            continue
        for ttyp, thsz, tsize, tp in chunks(arsc, cp + chsz, cp + csize):
            if ttyp != 0x0201:  # RES_TABLE_TYPE
                continue
            tid = arsc[tp + 8]
            if tid != type_id:
                continue
            entryCount, entriesStart = struct.unpack_from('<II', arsc, tp + 12)
            config_size = struct.unpack_from('<I', arsc, tp + 20)[0]
            offsets_pos = tp + 20 + config_size
            if entry_id >= entryCount:
                continue
            eoff = struct.unpack_from('<I', arsc, offsets_pos + entry_id * 4)[0]
            if eoff == 0xFFFFFFFF:
                continue
            ep = tp + entriesStart + eoff
            esize, eflags, ekey = struct.unpack_from('<HHI', arsc, ep)
            v_size, v_res0, v_type, v_data = struct.unpack_from('<HBBI', arsc, ep + esize)
            if v_type == 0x03 and global_pool and v_data < len(global_pool):
                return global_pool[v_data]
    return None


def label_of(apk):
    try:
        with zipfile.ZipFile(apk) as z:
            mf = z.read('AndroidManifest.xml')
            raw, resid = manifest_label(mf)
            if raw:
                return raw
            if resid:
                try:
                    arsc = z.read('resources.arsc')
                    return arsc_lookup(arsc, resid)
                except KeyError:
                    return None
    except Exception as e:
        return 'ERR:' + str(e)
    return None


if __name__ == '__main__':
    for p in sys.argv[1:]:
        print(p.split('\\')[-1].split('/')[-1], '->', label_of(p))
