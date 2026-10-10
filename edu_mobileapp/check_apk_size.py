import zipfile
import sys

apk_path = 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk'
with zipfile.ZipFile(apk_path, 'r') as z:
    entries = sorted(z.infolist(), key=lambda x: x.file_size, reverse=True)
    print(f"{'Uncompressed MB':>15} {'Compressed MB':>15}  File")
    print("-" * 75)
    for e in entries[:30]:
        uncomp = e.file_size / (1024 * 1024)
        comp = e.compress_size / (1024 * 1024)
        print(f"{uncomp:15.2f} {comp:15.2f}  {e.filename}")
