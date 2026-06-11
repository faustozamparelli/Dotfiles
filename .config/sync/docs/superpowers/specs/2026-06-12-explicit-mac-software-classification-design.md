# Explicit Mac Software Classification Design

## Goal

Make installed software local to the Mac where it was discovered unless Fausto
explicitly marks it as shared. Shared software is required and automatically
installed on both Macs.

The workflow must use a fresh inventory, so software already uninstalled before
the migration does not remain in the editable classification file.

## Scope

The editable classification file covers software with a supported automatic
installer:

- Homebrew packages
- Homebrew casks
- Mac App Store apps installed through `mas`

Applications found in `/Applications` without a corresponding Brew cask or App
Store entry remain inventory-only.

VS Code extensions and macOS App Shortcuts remain fully automatic and shared.
They do not appear in the classification file.

Marta's portable configuration files also remain fully automatic and shared:

```text
Library/Application Support/org.yanex.marta/conf.marco
Library/Application Support/org.yanex.marta/favorites.marco
```

The Marta preferences plist is excluded because it contains machine-local
window geometry, recent directories, selected filenames, and usage state.

## Classification File

Each Mac has one tracked editable file:

```text
review/<inventory-name>.txt
```

The file uses aligned columns and a dot to select a bucket:

```text
# type  item                      shared  local
brew    bat                       .       
brew    octave                            .
cask    marta                             .
mas     123456789 Example App     .       
```

Exactly one of `shared` or `local` must contain `.` for every row. New software
discovered on a Mac defaults to `local`.

The script validates the file before changing shared state or installing
software. Invalid rows, unknown types, duplicate items, or rows with zero or two
selected buckets stop the run with a clear error.

## Shared State

The existing files remain the generated desired state used for installation:

```text
shared/brew-leaves.txt
shared/brew-casks.txt
shared/mas-apps.txt
```

At each run, the script rebuilds these files from the items marked `shared`
across the current classification files. Users edit classification files, not
the generated shared files.

An item marked shared on either Mac is shared globally. Moving its dot from
`shared` to `local` explicitly declassifies it everywhere: matching rows in
other Macs' classification files also become local.

## Sync Flow

Each `sync-maintain` run performs these steps:

1. Pull tracked dotfiles.
2. Capture the current Mac's fresh Brew, cask, App Store, applications, VS Code,
   and shortcut inventory.
3. Reconcile the current Mac's classification file:
   - Detect software that was classified but is no longer installed.
   - Remove missing local rows.
   - For missing shared rows, declassify matching rows on every Mac to `local`,
     remove the current Mac's row, and stop requiring the item.
   - Add newly installed supported software as `local`.
   - Preserve classifications for software still installed.
4. Validate all classification files.
5. Rebuild the generated shared Brew, cask, and App Store lists.
6. Install shared software missing from the current Mac.
7. Refresh inventory and classification after installations.
8. Continue the existing automatic shared sync for VS Code extensions and App
   Shortcuts, and stage Marta's portable configuration files.
9. Stage tracked files and print a report.

This ordering means an external uninstall is authoritative. If a shared item is
uninstalled from one Mac, its row disappears there and matching rows on other
Macs become local. The item stops auto-installing everywhere.

The existing classification row distinguishes an intentional external uninstall
from software that has never been installed on a new Mac. A missing shared item
with no prior local classification row is installed normally.

## App Store Behavior

Mac App Store apps are identified by their numeric App Store ID and display
name. Shared App Store apps are installed with `mas install` when `mas` is
available and the user is signed into the App Store.

If `mas list` cannot provide a reliable inventory, the script reports the issue
and does not remove existing App Store classifications during that run.

## Migration

On the first run after this change:

- Generate the current Mac's classification file only from its fresh installed
  inventory.
- Mark currently installed items already present in the old shared lists as
  `shared`.
- Mark every other currently installed supported item as `local`.
- Do not retain items that are no longer installed on the current Mac.

Existing classification files for another Mac are preserved until that Mac runs
the updated workflow and refreshes its own state.

Marta, now installed as a Brew cask, will be discovered and added as `local`
unless Fausto marks it shared.

## Error Handling

- Stop before installations when a classification file is invalid.
- Do not infer App Store uninstalls when `mas` inventory is unavailable or
  unreliable.
- Report failed installations without rewriting the item as local.
- Never uninstall software. Removal is always performed externally by Fausto.

## Testing

Automated tests cover:

- Fresh discoveries default to local.
- Existing shared installed items migrate as shared.
- Already-uninstalled items do not enter the classification file.
- External uninstall removes a local row.
- External uninstall removes a shared row, declassifies matching rows on other
  Macs, and stops automatic installation.
- A shared item never previously installed on a Mac installs on that Mac.
- Marta and other newly installed casks are tracked.
- App Store classification and installation by numeric ID.
- Invalid dot selections stop before state changes.
- VS Code extensions and shortcuts retain their existing automatic shared
  behavior.
- Marta's portable configuration files are tracked while its machine-local
  preferences plist remains excluded.
