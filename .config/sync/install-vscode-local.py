#!/usr/bin/env python3
"""Package/install the tiny tracked PDF opener; generated VSIX/state stay local."""
import json
from pathlib import Path
import subprocess
import tempfile
import zipfile


def main():
    cli = Path('/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code')
    if not cli.exists():
        return
    source = Path(__file__).with_name('vscode-preview-pdf')
    package = json.loads((source / 'package.json').read_text())
    installed = list((Path.home() / '.vscode/extensions').glob('fausto.preview-pdf-*'))
    if any(all((entry / name).exists() and (entry / name).read_bytes() == (source / name).read_bytes()
               for name in ('extension.js',)) and
           json.loads((entry / 'package.json').read_text()).get('version') == package['version']
           for entry in installed):
        return
    manifest = f'''<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
 <Metadata>
  <Identity Language="en-US" Id="preview-pdf" Version="{package['version']}" Publisher="fausto"/>
  <DisplayName>Open PDFs in Preview</DisplayName>
  <Description xml:space="preserve">Open PDFs in the system default app.</Description>
  <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="^1.90.0"/></Properties>
 </Metadata>
 <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
 <Dependencies/>
 <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>'''
    content_types = '''<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="json" ContentType="application/json"/>
 <Default Extension="js" ContentType="application/javascript"/>
 <Default Extension="vsixmanifest" ContentType="text/xml"/>
</Types>'''
    with tempfile.TemporaryDirectory(prefix='vscode-preview-pdf-') as folder:
        vsix = Path(folder) / 'preview-pdf.vsix'
        with zipfile.ZipFile(vsix, 'w', zipfile.ZIP_DEFLATED) as archive:
            archive.writestr('extension.vsixmanifest', manifest)
            archive.writestr('[Content_Types].xml', content_types)
            for name in ('package.json', 'extension.js'):
                archive.write(source / name, 'extension/' + name)
        subprocess.run([str(cli), '--install-extension', str(vsix), '--force'], check=True)


if __name__ == '__main__':
    main()
