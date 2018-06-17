#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
#               <URL:http://github.com/LucHermitte/lh-vim-lib>
# Version:      4.5.0
#
# Support script for lh-vim-lib to tell which codepoints have a corresponding
# glyph in a given font set.
#
# Merge between
# - https://unix.stackexchange.com/a/268286/3240
# - https://apple.stackexchange.com/a/291200
# Requires:
# - pip install python-fontconfig
import re, sys

def code_points(text):
    import struct
    utf32 = text.encode('UTF-32LE')
    return struct.unpack('<{}I'.format(len(utf32) // 4), utf32)

def does_support(enc, font, chars):
    import fontconfig
    fonts = fontconfig.query()
    font_re = re.compile(sys.argv[2])
    # print(fonts)
    fonts = [path for path in fonts if re.search(font_re, path) ]
    if len(fonts) == 0:
        return {'_error': 'No font found for '+font}
    # print(fonts)
    res = {}

    for c in chars:
        if c.startswith('U+'):
            if (sys.version_info > (3, 0)): # python 3
                c_dec = chr(int(c[2:], 16))
            else: # python 2
                c_dec =  ('\\U%08x' % int(c[2:], 16)).decode('unicode-escape')
        elif isinstance(c, bytes):
            c_dec = c.decode(enc)
        else:
            c_dec = c
        # print(c)
        # c_dec = c.decode(enc) if isinstance(c, bytes) else c
        cp = code_points(c_dec)
        # print(cp)
        if sys.maxunicode < cp[0]:
            # With some python versions, we cannot decode "high" unicode code points
            # even if the CP has a glyph in the current fontset :(
            res.update({c: 0})
            continue
        for path in fonts:
            font = fontconfig.FcFont(path)
            # print('%s ' % (c_dec, ))
            if font.has_char(c_dec):
                # print('%s -> OK in %s' % (c_dec, font))
                res.update({c_dec: 1})
                break
        else:
          res.update({c_dec: 0})

    return res

if __name__ == '__main__':
    # $1: encoding
    # $2: font name regex
    # $3..$n: codepoint list
    enc     = sys.argv[1]
    font    = sys.argv[2]
    chars   = sys.argv[3:]
    res = does_support(enc, font, chars)

    print(res)

