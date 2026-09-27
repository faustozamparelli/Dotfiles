#!/usr/bin/env python3
"""Retire the old file opener and VS Code defaults on each Mac."""
import os
import plistlib
import shutil
import subprocess
from pathlib import Path

home = Path.home()
prefs = home / 'Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist'
app = home / 'Applications/Open in Herdr.app'
former = 'com.fausto.open-in-herdr'
changed = False

if prefs.exists():
    data = plistlib.loads(prefs.read_bytes())
    for row in data.get('LSHandlers', []):
        for key, value in list(row.items()):
            if key.startswith('LSHandlerRole') and value in {former, 'com.microsoft.VSCode'}:
                tag = row.get('LSHandlerContentTag', '')
                content_type = row.get('LSHandlerContentType', '')
                row[key] = ('net.imput.helium' if tag in {'md', 'markdown', 'html', 'htm'}
                            or content_type in {'net.daringfireball.markdown', 'public.html'}
                            else 'com.apple.TextEdit')
                changed = True
    if changed:
        temporary = prefs.with_name(prefs.name + '.dotfiles-tmp')
        temporary.write_bytes(plistlib.dumps(data))
        temporary.chmod(prefs.stat().st_mode & 0o777)
        os.replace(temporary, prefs)
        subprocess.run(['killall', 'cfprefsd'], stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, check=False)

if app.exists():
    subprocess.run(['/System/Library/Frameworks/CoreServices.framework/Frameworks/'
                    'LaunchServices.framework/Support/lsregister', '-u', str(app)],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    shutil.rmtree(app)
