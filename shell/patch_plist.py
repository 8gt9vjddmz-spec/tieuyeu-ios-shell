import plistlib
import sys

p = sys.argv[1]
d = plistlib.loads(open(p, 'rb').read())
d['UISupportedInterfaceOrientations'] = ['UIInterfaceOrientationPortrait']
d['UISupportedInterfaceOrientations~ipad'] = ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown']
d['CFBundleDisplayName'] = 'Tiểu Yêu'
d['NSLocalNetworkUsageDescription'] = 'Kết nối tới máy chủ game trong mạng nội bộ.'
d['UIFileSharingEnabled'] = True
d['LSSupportsOpeningDocumentsInPlace'] = True
d['UIRequiredDeviceCapabilities'] = ['arm64']
d['CFBundleShortVersionString'] = '10.0.0'
d['ITSAppUsesNonExemptEncryption'] = False
open(p, 'wb').write(plistlib.dumps(d))
