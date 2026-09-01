!/bin/bash
#
# FLUXDOCTOR V1.1
# 
set -eu

cleanup() {
    local exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
        echo
        echo "❌ exit code: $exit_code" >&2
    fi
}
trap cleanup EXIT

os_name="$(uname -s)"
case $os_name in
  Darwin) # macOS
    emulator='/Applications/Virtual ][.app/Contents/MacOS/Virtual ]['
    emulatorurl="https://www.virtualii.com/"
    AC="$HOME/.local/bin/ac-mac-aarch64-13.1"
    ;;
  Linux) # Linux
    emulator="todo"
    emulatorurl="todo"
    AC="$HOME/ac-linux-*-13.1.exe"
    ;;
  MINGW64*) # Windows Git Bash
    emulator="AppleWin"
    emulatorurl="https://github.com/AppleWin/AppleWin"
    AC="$HOME/ac-windows-amd64-13.1.exe"
    ;;
  *)
    echo "ERROR: Unknown OS `$os_name`" 1>&2
    ;;
esac

if ! type -p dasm >/dev/null 2>&1; then
    echo "ERROR, missing executable:" 1>&2
    echo "  dasm" 1>&2
    echo "" 1>&2
    echo "Please install dasm from:" 1>&2
    echo "  https://dasm-assembler.github.io/" 1>&2
    exit 1
fi

if ! type -p "$emulator" >/dev/null 2>&1; then
    echo "ERROR, missing executable:" 1>&2
    echo "  $emulator" 1>&2
    echo "" 1>&2
    echo "Please install $emulator from:" 1>&2
    echo "  $emulatorurl" 1>&2
    exit 1
fi

if [[ ! -x "$AC" ]]; then
    echo "ERROR missing executable:" 1>&2
    echo "  $AC" 1>&2
    echo "" 1>&2
    echo "Please install Apple Commander (`ac` CLI) from:" 1>&2
    echo "  https://applecommander.github.io/installation/command-line/" 1>&2
    exit 1
fi

if ! type -p fluxrider >/dev/null 2>&1; then
    echo "ERROR missing executable:" 1>&2
    echo "  fluxrider" 1>&2
    echo "" 1>&2
    echo "Please install fluxrider from:" 1>&2
    echo "  https://bitbucket.org/fredsa/fluxrider" 1>&2
    exit 1
fi

if [[ ! -r fluxdoctor.asm ]]; then
    echo "MISSING: fluxdoctor.asm" 1>&2
    exit 1
fi

echo "====================================================================="
echo "Cleanup output folder: out/"
mkdir -p out
rm -f out/fluxdoctor.do
rm -f out/fluxdoctor.out
rm -f out/fluxdoctor.bin
rm -f out/fluxdoctor-basic.wav
rm -f out/fluxdoctor-basic.mon

echo
echo "====================================================================="
echo "Compiling tape:"
echo "  fluxdoctor.asm -> out/fluxdoctor.out"
dasm fluxdoctor.asm -f3 -oout/fluxdoctor.out

echo
echo "====================================================================="
echo "Extracting file bytes (removing 4 byte header):"
# Get start address in hex from first two byte.
startaddr="0x$(od -An -t x2 -N2 out/fluxdoctor.out | tr -d ' ')"
echo "  => start address: $startaddr"
echo "  out/fluxdoctor.out -> out/fluxdoctor.bin"
# Remove first four bytes (start + len)
cat out/fluxdoctor.out | tail -c+5 > out/fluxdoctor.bin

echo
echo "====================================================================="
echo "Creating out/fluxdoctor-basic.bin"
# `42 CALL 2061`
printf '\x0B\x08\x2A\x00\x8C\x32\x30\x36\x31\x00\x00\x00' > out/fluxdoctor-basic.bin
cat out/fluxdoctor.bin >> out/fluxdoctor-basic.bin

echo
echo "====================================================================="
echo "Creating blank disk image:"
echo "  template/hello.do -> out/fluxdoctor.do"
# $AC -dos140 out/fluxdoctor.do
cp template/hello.do out/fluxdoctor.do
# ls -l out/fluxdoctor.do
echo "Removing pre-existing FLUXDOCTOR from template disk image:"
echo "  out/fluxdoctor.do : delete FLUXDOCTOR"
$AC -d out/fluxdoctor.do FLUXDOCTOR

# https://applecommander.github.io/cli/ac/#putting-files-and-file-types
# https://en.wikipedia.org/wiki/Apple_DOS#Technical_details
echo
echo "====================================================================="
echo "Adding FLUXDOCTOR program to disk image:"
echo "  out/fluxdoctor-basic.bin -> FLUXDOCTOR"
$AC -p out/fluxdoctor.do FLUXDOCTOR A < out/fluxdoctor-basic.bin

echo
echo "====================================================================="
echo "Final disk image is ready:"
echo "  out/fluxdoctor.do"
$AC -ll out/fluxdoctor.do

echo
echo "====================================================================="
echo "Creating cassette bootable WAV file:"
echo "  out/fluxdoctor-basic.bin -> out/fluxdoctor-basic.wav"
fluxrider out/fluxdoctor-basic.bin out/fluxdoctor-basic.wav

echo
echo "Creating monitor type-in version of tape program:"
echo "====================================================================="
echo "  out/fluxdoctor-basic.bin -> out/fluxdoctor-basic.mon"
# BASIC start address
echo -n "0801" > out/fluxdoctor-basic.mon
xxd -p -c 8 out/fluxdoctor-basic.bin \
  | awk '{gsub(/(..)/, "& "); print ":" toupper($0)}' \
  >> out/fluxdoctor-basic.mon

echo
echo "====================================================================="
echo "To write image to a physical floppy using greaseweazle:"
echo "  gw write --tracks=step=2 out/fluxdoctor.do    # 96TPI floppy drive"
echo "  gw write out/fluxdoctor.do                    # 48TPI floppy drive"

os_name="$(uname -s)"
case $os_name in
  Darwin)
    # macOS
    '/Applications/Virtual ][.app/Contents/MacOS/Virtual ][' out/fluxdoctor.do
    # '/Applications/Virtual ][.app/Contents/MacOS/Virtual ][' out/fluxdoctor-basic.wav
    ;;
  Linux)
    # Linux
    echo "TODO: launch emulator with disk image: out/fluxdoctor.do"
    ;;
  MINGW64*)
    # Windows Git Bash
    echo "Launching AppleWin emulator"
    AppleWin -d1 out/fluxdoctor.do
    ;;
  *)
    echo "ERROR: Unknown OS name for `$os_name`" 1>&2
    ;;
esac
