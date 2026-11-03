#!/usr/bin/env python3
"""Install tracked local VS Code extensions; generated VSIX/state stay local."""
import json
from pathlib import Path
import subprocess
import tempfile
import zipfile
from xml.sax.saxutils import escape


def install(source, cli):
    package = json.loads((source / 'package.json').read_text())
    files = sorted(path.name for path in source.iterdir() if path.is_file())
    extension_id = f"{package['publisher']}.{package['name']}"
    installed = list((Path.home() / '.vscode/extensions').glob(f'{extension_id}-*'))
    # VS Code adds machine-local __metadata to the installed manifest.
    if any(all((entry / name).exists() and (entry / name).read_bytes() == (source / name).read_bytes()
               for name in files if name != 'package.json') and
           (entry / 'package.json').exists() and
           {key: value for key, value in json.loads((entry / 'package.json').read_text()).items()
            if key != '__metadata'} == package
           for entry in installed):
        return
    manifest = f'''<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
 <Metadata>
  <Identity Language="en-US" Id="{escape(package['name'])}" Version="{escape(package['version'])}" Publisher="{escape(package['publisher'])}"/>
  <DisplayName>{escape(package['displayName'])}</DisplayName>
  <Description xml:space="preserve">{escape(package['description'])}</Description>
  <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="{escape(package['engines']['vscode'])}"/></Properties>
 </Metadata>
 <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
 <Dependencies/>
 <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>'''
    content_types = '''<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="json" ContentType="application/json"/>
 <Default Extension="js" ContentType="application/javascript"/>
 <Default Extension="css" ContentType="text/css"/>
 <Default Extension="vsixmanifest" ContentType="text/xml"/>
</Types>'''
    with tempfile.TemporaryDirectory(prefix=f'{extension_id}-') as folder:
        vsix = Path(folder) / f"{package['name']}.vsix"
        with zipfile.ZipFile(vsix, 'w', zipfile.ZIP_DEFLATED) as archive:
            archive.writestr('extension.vsixmanifest', manifest)
            archive.writestr('[Content_Types].xml', content_types)
            for name in files:
                archive.write(source / name, 'extension/' + name)
        subprocess.run([str(cli), '--install-extension', str(vsix), '--force'], check=True)


def main():
    cli = Path('/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code')
    if not cli.exists():
        return
    for name in ('vscode-markdown-preview-wrap',):
        install(Path(__file__).with_name(name), cli)


if __name__ == '__main__':
    main()
