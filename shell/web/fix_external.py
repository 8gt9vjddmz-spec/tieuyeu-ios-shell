"""Hoan thien ban build engine web: xu ly cac import "external:emscripten/spine/*"
ma trinh build cua Cocos Creator thuong tu lam (o day ta build bang CLI nen phai tu lam)."""
import os
import re
import shutil
import sys

out, ext = sys.argv[1], sys.argv[2]          # out/cocos-js , engine/native/external/emscripten/spine
dst = os.path.join(out, 'spine')
os.makedirs(dst, exist_ok=True)


def to_system(src_path, dst_path):
    code = open(src_path, encoding='utf-8').read()
    code = code.replace('import.meta', '_context.meta')
    code, n = re.subn(r'export\s+default\s+([A-Za-z_$][\w$]*)\s*;?', r'_export("default", \1);', code)
    if n == 0:
        # CommonJS / bien toan cuc: lay ten bien dau tien
        m = re.search(r'var\s+([A-Za-z_$][\w$]*)\s*=', code)
        code += '\n_export("default", %s);\n' % m.group(1)
    wrapped = ('System.register([], function (_export, _context) {\n  "use strict";\n'
               '  return { setters: [], execute: function () {\n' + code + '\n  } };\n});\n')
    open(dst_path, 'w', encoding='utf-8').write(wrapped)


def url_module(file_name, dst_path):
    open(dst_path, 'w', encoding='utf-8').write(
        'System.register([], function (_export, _context) {\n  "use strict";\n'
        '  return { setters: [], execute: function () {\n'
        '    _export("default", new URL("./%s", _context.meta.url).href);\n  } };\n});\n' % file_name)


print('spine external files:', os.listdir(ext))
to_system(os.path.join(ext, 'spine.wasm.js'), os.path.join(dst, 'spine.wasm.sys.js'))
to_system(os.path.join(ext, 'spine.asm.js'), os.path.join(dst, 'spine.asm.sys.js'))
shutil.copy(os.path.join(ext, 'spine.wasm'), os.path.join(dst, 'spine.wasm'))
shutil.copy(os.path.join(ext, 'spine.js.mem'), os.path.join(dst, 'spine.js.mem'))
url_module('spine.wasm', os.path.join(dst, 'spine.wasm.url.js'))
url_module('spine.js.mem', os.path.join(dst, 'spine.js.mem.url.js'))

cc = os.path.join(out, 'cc.js')
s = open(cc, encoding='utf-8').read()
rep = {
    'external:emscripten/spine/spine.asm.js': './spine/spine.asm.sys.js',
    'external:emscripten/spine/spine.js.mem': './spine/spine.js.mem.url.js',
    'external:emscripten/spine/spine.wasm.js': './spine/spine.wasm.sys.js',
    'external:emscripten/spine/spine.wasm': './spine/spine.wasm.url.js',
}
for k in sorted(rep, key=len, reverse=True):
    c = s.count('"%s"' % k)
    s = s.replace('"%s"' % k, '"%s"' % rep[k])
    print(k, '->', rep[k], c)
left = re.findall(r'external:[\w/.\-]+', s)
print('external imports left:', sorted(set(left)))
open(cc, 'w', encoding='utf-8').write(s)
