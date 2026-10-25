"""Extract minSdkVersion / targetSdkVersion / package name from an APK's binary AndroidManifest.xml.

Minimal AXML reader: enough for uses-sdk and manifest@package.
Usage: python apk_minsdk.py <apk> [<apk> ...]
"""
import sys
import zipfile
import struct

RES_XML_TYPE = 0x0003
RES_STRING_POOL_TYPE = 0x0001
RES_XML_START_ELEMENT_TYPE = 0x0102
RES_XML_RESOURCE_MAP_TYPE = 0x0180

TYPE_REFERENCE = 0x01
TYPE_STRING = 0x03
TYPE_FIRST_INT = 0x10
TYPE_INT_DEC = 0x10
TYPE_INT_HEX = 0x11


def read_string_pool(data, off):
    # off points at chunk header
    _, header_size, size = struct.unpack_from('<HHI', data, off)
    count, style_count, flags, strings_start, styles_start = struct.unpack_from('<IIIII', data, off + 8)
    utf8 = bool(flags & 0x100)
    offsets = struct.unpack_from('<%dI' % count, data, off + header_size)
    base = off + strings_start
    out = []
    for o in offsets:
        p = base + o
        if utf8:
            # u16len then u8len (each 1-2 bytes)
            n = data[p]
            p += 1
            if n & 0x80:
                p += 1
            n2 = data[p]
            p += 1
            if n2 & 0x80:
                n2 = ((n2 & 0x7F) << 8) | data[p]
                p += 1
            out.append(data[p:p + n2].decode('utf-8', 'replace'))
        else:
            n = struct.unpack_from('<H', data, p)[0]
            p += 2
            if n & 0x8000:
                n = ((n & 0x7FFF) << 16) | struct.unpack_from('<H', data, p)[0]
                p += 2
            out.append(data[p:p + n * 2].decode('utf-16-le', 'replace'))
    return out


def parse(apk):
    with zipfile.ZipFile(apk) as z:
        data = z.read('AndroidManifest.xml')
    # walk top-level chunks after the XML file header (8 bytes)
    off = 8
    strings = []
    resmap = []
    package = None
    min_sdk = None
    target_sdk = None
    while off + 8 <= len(data):
        ctype, hsize, csize = struct.unpack_from('<HHI', data, off)
        if csize == 0:
            break
        if ctype == RES_STRING_POOL_TYPE:
            strings = read_string_pool(data, off)
        elif ctype == RES_XML_RESOURCE_MAP_TYPE:
            n = (csize - hsize) // 4
            resmap = list(struct.unpack_from('<%dI' % n, data, off + hsize))
        elif ctype == RES_XML_START_ELEMENT_TYPE:
            body = off + hsize
            ns_i, name_i, attr_start, attr_size, attr_count = struct.unpack_from('<IIHHH', data, body)
            el_name = strings[name_i] if name_i < len(strings) else '?'
            attrs = {}
            for i in range(attr_count):
                a = body + attr_start + i * attr_size
                a_ns, a_name, a_raw = struct.unpack_from('<III', data, a)
                t_size, t_res0, t_type, t_data = struct.unpack_from('<HBBI', data, a + 12)
                key = strings[a_name] if a_name < len(strings) else '?'
                if t_type == TYPE_STRING:
                    val = strings[t_data] if t_data < len(strings) else '?'
                elif t_type >= TYPE_FIRST_INT:
                    val = t_data
                else:
                    val = 'type=0x%02x data=0x%x' % (t_type, t_data)
                attrs[key] = val
            if el_name == 'uses-sdk':
                min_sdk = attrs.get('minSdkVersion', min_sdk)
                target_sdk = attrs.get('targetSdkVersion', target_sdk)
            if el_name == 'manifest' and 'package' in attrs:
                package = attrs['package']
        off += csize
    return package, min_sdk, target_sdk


if __name__ == '__main__':
    for apk in sys.argv[1:]:
        try:
            pkg, mn, tg = parse(apk)
            print('%-34s package=%-34s minSdk=%-5s targetSdk=%s' % (apk.split('\\')[-1], pkg, mn, tg))
        except Exception as e:
            print('%-34s ERROR %s' % (apk.split('\\')[-1], e))
