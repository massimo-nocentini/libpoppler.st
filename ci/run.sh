#!/bin/sh
# run.sh - load libpoppler.st into a Pharo image and run its tests on a VM
#
#   sh ci/run.sh <vm-dir> <image.zip | X.image>
#
# <vm-dir> holds the VM: pharo (Linux), Pharo.app (macOS; or <vm-dir> is the
# .app itself) or PharoConsole.exe (Windows, from an MSYS2 or Git Bash shell).
# The VM of the cairo stack (pharo-vm, FEATURE_LIB_POPPLER) carries
# libpoppler-glib, libglib and libgobject next to it; on another VM the
# system's libraries are used.  <image> is a Pharo 12 to 15 image, zipped or
# not.  The script copies the image into a directory of its own (CI_WORK_DIR,
# or a new one in TMPDIR), then runs ci/ci-load.st on it: Metacello locks
# LibPangoCairo to a local checkout of libpangocairo.st, loads this checkout's
# baseline (no network), checks the loaded packages and runs their tests.  The
# image is never saved.
#
# The status is 0 when the summary line
#   LibPoppler <pharo-version> loaded <groups> tests ... poppler <version> ok
# was printed, else 1 (2 for a usage error).
#
# Environment: LIBPANGOCAIRO_DIR (the checkout of libpangocairo.st whose GLib
# group is loaded; ../libpangocairo.st next to this checkout by default),
# CI_WORK_DIR, CI_TIMEOUT (seconds, 1800 by default), CI_GROUPS (the groups to
# load instead of ci-load.st's choice), PHARO_CAIRO_STACK_EXPECT_LIBS (yes by
# default: a missing library is a test failure, not a skip),
# POPPLER_EXPECT_VERSION (the poppler version the tests must find).

if test $# -ne 2; then
    echo "usage: $0 <vm-dir> <image.zip | X.image>" >&2
    exit 2
fi
VM_DIR=$(cd "$1" && pwd) || exit 2
IMAGE=$2
REPO=$(cd "$(dirname "$0")/.." && pwd) || exit 2
PANGO_DIR=${LIBPANGOCAIRO_DIR:-$REPO/../libpangocairo.st}
if ! test -d "$PANGO_DIR/src/BaselineOfLibPangoCairo"; then
    echo "FAIL: no src/BaselineOfLibPangoCairo in $PANGO_DIR (set LIBPANGOCAIRO_DIR to a checkout of libpangocairo.st)" >&2
    exit 1
fi
PANGO_DIR=$(cd "$PANGO_DIR" && pwd) || exit 1

# the VM executable
lib_path=no
if test -x "$VM_DIR/pharo" && ! test -d "$VM_DIR/pharo"; then
    vm=$VM_DIR/pharo
    lib_path=yes
elif test -x "$VM_DIR/Pharo.app/Contents/MacOS/Pharo"; then
    vm=$VM_DIR/Pharo.app/Contents/MacOS/Pharo
elif test -x "$VM_DIR/Contents/MacOS/Pharo"; then
    vm=$VM_DIR/Contents/MacOS/Pharo
elif test -f "$VM_DIR/PharoConsole.exe"; then
    vm=$VM_DIR/PharoConsole.exe
else
    echo "FAIL: no pharo, Pharo.app/Contents/MacOS/Pharo, Contents/MacOS/Pharo or PharoConsole.exe in $VM_DIR" >&2
    exit 1
fi

# a copy of the image
WORK=${CI_WORK_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/libpoppler-ci.XXXXXX")} || exit 1
mkdir -p "$WORK" || exit 1
WORK=$(cd "$WORK" && pwd)
case $IMAGE in
*.zip)
    rm -rf "$WORK/zip"
    mkdir -p "$WORK/zip" && unzip -q -o "$IMAGE" -d "$WORK/zip" || exit 1
    image=$(find "$WORK/zip" -name '*.image' | head -1)
    ;;
*.image)
    image=$IMAGE
    ;;
*)
    echo "FAIL: $IMAGE is neither a .zip nor a .image" >&2
    exit 1
    ;;
esac
if test -z "$image" || ! test -f "$image"; then
    echo "FAIL: no image in $IMAGE" >&2
    exit 1
fi
rm -f "$WORK/CI.image" "$WORK/CI.changes" "$WORK/PharoDebug.log" "$WORK/ci-load.out"
cp "$image" "$WORK/CI.image" || exit 1
changes=${image%.image}.changes
if test -f "$changes"; then cp "$changes" "$WORK/CI.changes"; else : >"$WORK/CI.changes"; fi
cp "$(dirname "$image")"/*.sources "$WORK/" 2>/dev/null
rm -rf "$WORK/zip"

# paths as the VM sees them (Windows: C:/... from an MSYS2 or Git Bash shell)
native() {
    if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi
}
LIBPOPPLER_DIR=$(native "$REPO")
LIBPANGOCAIRO_DIR=$(native "$PANGO_DIR")
PHARO_CAIRO_STACK_EXPECT_LIBS=${PHARO_CAIRO_STACK_EXPECT_LIBS:-yes}
export LIBPOPPLER_DIR LIBPANGOCAIRO_DIR PHARO_CAIRO_STACK_EXPECT_LIBS
script=$(native "$REPO/ci/ci-load.st")
echo "image: $image, copied to $WORK/CI.image"
echo "vm: $vm"
echo "checkout: $REPO, libpangocairo.st: $PANGO_DIR (PHARO_CAIRO_STACK_EXPECT_LIBS=$PHARO_CAIRO_STACK_EXPECT_LIBS)"

limit=
if command -v timeout >/dev/null 2>&1; then limit="timeout ${CI_TIMEOUT:-1800}"
elif command -v gtimeout >/dev/null 2>&1; then limit="gtimeout ${CI_TIMEOUT:-1800}"
fi
# LD_LIBRARY_PATH: the libraries next to a Linux VM load the libraries they
# need from there (the pharo of a build may name its build directory)
if test $lib_path = yes; then
    (cd "$WORK" && LD_LIBRARY_PATH="$VM_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
	$limit "$vm" --headless CI.image --no-default-preferences st "$script") >"$WORK/ci-load.out" 2>&1
else
    (cd "$WORK" && $limit "$vm" --headless CI.image --no-default-preferences st "$script") >"$WORK/ci-load.out" 2>&1
fi
status=$?
tr -d '\r' <"$WORK/ci-load.out"

summary=$(tr -d '\r' <"$WORK/ci-load.out" | grep '^LibPoppler [0-9][0-9.]* loaded ' | tail -1)
if test $status -eq 0 && echo "$summary" | grep ' ok$' >/dev/null; then
    echo "PASS: $vm ($WORK)"
    exit 0
fi
if test $status -eq 124; then
    echo "FAIL: timeout after ${CI_TIMEOUT:-1800} s ($WORK)"
elif test -z "$summary"; then
    echo "FAIL: no summary line, exit status $status ($WORK)"
else
    echo "FAIL: exit status $status ($WORK)"
fi
exit 1
