#!/opt/homebrew/bin/fish

set -g SIOYEK_UPDATER_SOURCE (status filename)
set -g SIOYEK_QT_VERSION 6.11.0

function cleanup --on-event fish_exit
    cd /
    if set -q SIOYEK_TMP; and string match -qr '^/private/tmp/sioyek-build\.[A-Za-z0-9]+$' -- "$SIOYEK_TMP"
        rm -rf -- "$SIOYEK_TMP"
    end
end

function fail
    echo "FAILED: $argv" >&2
    exit 1
end

set -gx SIOYEK_TMP (mktemp -d /private/tmp/sioyek-build.XXXXXX)
or fail "could not create temporary directory"

mkdir -p "$SIOYEK_TMP/tmp" "$SIOYEK_TMP/cache" "$SIOYEK_TMP/home"
or fail "could not initialize temporary directory"

cd "$SIOYEK_TMP"
or fail "could not enter temporary directory"

/usr/bin/python3 -m venv "$SIOYEK_TMP/venv"
or fail "python venv creation failed"

env \
    HOME="$SIOYEK_TMP/home" \
    XDG_CACHE_HOME="$SIOYEK_TMP/cache" \
    PIP_NO_CACHE_DIR=1 \
    "$SIOYEK_TMP/venv/bin/python" -m pip install \
    --disable-pip-version-check \
    aqtinstall
or fail "aqtinstall installation failed"

env \
    HOME="$SIOYEK_TMP/home" \
    XDG_CACHE_HOME="$SIOYEK_TMP/cache" \
    TMPDIR="$SIOYEK_TMP/tmp" \
    "$SIOYEK_TMP/venv/bin/python" -m aqt install-qt \
    --outputdir "$SIOYEK_TMP/qt" \
    mac desktop "$SIOYEK_QT_VERSION" clang_64 \
    --archives qtbase qtdeclarative qtsvg qttools \
    -m qtspeech qtmultimedia
or fail "Qt installation failed"

set QT "$SIOYEK_TMP/qt/$SIOYEK_QT_VERSION/macos"

test -d "$QT/lib/QtTextToSpeech.framework"
or fail "QtTextToSpeech was not installed"

set -gx PATH "$QT/bin" $PATH
set -gx Qt6_DIR "$QT"
set -gx QT_PLUGIN_PATH "$QT/plugins"
set -gx PKG_CONFIG_PATH "$QT/lib/pkgconfig"
set -gx QML2_IMPORT_PATH "$QT/qml"

echo "Using temporary Qt:"
qmake --version

qmake -query QT_INSTALL_PREFIX | grep -Fq "$QT"
or fail "wrong qmake is active"

set CHECK "$SIOYEK_TMP/qt-check"
mkdir "$CHECK"

printf "%s\n" \
    "QT += core texttospeech" \
    "CONFIG += sdk_no_version_check" \
    "QMAKE_CXXFLAGS += -Wno-implicit-function-declaration" \
    "SOURCES += main.cpp" \
    > "$CHECK/check.pro"

printf "%s\n" \
    "#include <QCoreApplication>" \
    "#include <QTextToSpeech>" \
    "int main(int argc, char **argv) { QCoreApplication a(argc, argv); return 0; }" \
    > "$CHECK/main.cpp"

cd "$CHECK"
qmake check.pro
or fail "qmake cannot find Qt TextToSpeech"
make
or fail "Qt TextToSpeech compile check failed"

git clone \
    --branch development \
    --depth 1 \
    --recursive \
    --shallow-submodules \
    https://github.com/ahrm/sioyek.git \
    "$SIOYEK_TMP/sioyek"
or fail "Sioyek clone failed"

cd "$SIOYEK_TMP/sioyek"
or fail "could not enter Sioyek source"

set -l build_commit (git rev-parse HEAD)
set -l build_date (date -u '+%Y-%m-%dT%H:%M:%SZ')

printf '\n# Compatibility with current Apple Clang / macOS SDK.\nQMAKE_CXXFLAGS += -Wno-implicit-function-declaration\n' \
    >> pdf_viewer_build_config.pro

env MAKE_PARALLEL=(sysctl -n hw.logicalcpu) ./build_mac.sh
or fail "Sioyek build failed"

test -d build/sioyek.app
or fail "build did not produce sioyek.app"

set -l runtime_path "$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
/usr/libexec/PlistBuddy -c "Set :LSEnvironment:PATH $runtime_path" build/sioyek.app/Contents/Info.plist
or fail "could not sanitize the application PATH"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Sioyek" build/sioyek.app/Contents/Info.plist
or /usr/libexec/PlistBuddy -c "Set :CFBundleName Sioyek" build/sioyek.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Sioyek" build/sioyek.app/Contents/Info.plist
or /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Sioyek" build/sioyek.app/Contents/Info.plist

mkdir -p build/sioyek.app/Contents/Resources
cp "$SIOYEK_UPDATER_SOURCE" build/sioyek.app/Contents/Resources/update-from-source.fish
or fail "could not bundle updater"
printf "branch=development\ncommit=%s\nbuilt=%s\nqt=%s\n" "$build_commit" "$build_date" "$SIOYEK_QT_VERSION" \
    > build/sioyek.app/Contents/Resources/source-build-info.txt

"$QT/bin/macdeployqt" build/sioyek.app
or fail "macdeployqt failed"

codesign --force --deep --sign - build/sioyek.app
or fail "codesign failed"

codesign --verify --deep --strict build/sioyek.app
or fail "bundle verification failed"

set -l linked_paths (find build/sioyek.app -type f -perm -111 -exec otool -L '{}' ';' 2>/dev/null)
if printf '%s\n' $linked_paths | grep -E '/private/tmp/sioyek-build|/opt/homebrew/(Cellar/)?qt'
    fail "final app still references a temporary or Homebrew Qt installation"
end

set -l source_app "$SIOYEK_TMP/sioyek/build/sioyek.app"
if test -w /Applications
    rm -rf /Applications/.sioyek-codex-new /Applications/.sioyek-codex-old
    ditto "$source_app" /Applications/.sioyek-codex-new
    or fail "could not stage Sioyek"
    if test -e /Applications/Sioyek.app
        mv /Applications/Sioyek.app /Applications/.sioyek-codex-old
        or fail "could not back up previous Sioyek"
    end
    mv /Applications/.sioyek-codex-new /Applications/Sioyek.app
    or fail "could not activate Sioyek"
    rm -rf /Applications/.sioyek-codex-old
else
    osascript \
        -e 'on run argv' \
        -e 'set src to item 1 of argv' \
        -e 'set cmd to "set -eu; new=/Applications/.sioyek-codex-new; old=/Applications/.sioyek-codex-old; rm -rf \"$new\" \"$old\"; /usr/bin/ditto " & quoted form of src & " \"$new\"; if [ -e /Applications/Sioyek.app ]; then /bin/mv /Applications/Sioyek.app \"$old\"; fi; /bin/mv \"$new\" /Applications/Sioyek.app; rm -rf \"$old\""' \
        -e 'do shell script cmd with administrator privileges' \
        -e 'end run' \
        -- "$source_app"
    or fail "administrator installation was cancelled or failed"
end

codesign --verify --deep --strict /Applications/Sioyek.app
or fail "installed app failed code-signature verification"

test -x /Applications/Sioyek.app/Contents/MacOS/sioyek
or fail "installed executable is missing"

echo
echo "Installed successfully: /Applications/Sioyek.app"
echo "Source commit: $build_commit"
echo "Updater: fish /Applications/Sioyek.app/Contents/Resources/update-from-source.fish"
