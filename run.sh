#!/bin/bash
#
# FLUXDOCTOR V1.1
# 
set -eu

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

echo "Creating blank image:"
echo "  images/hello.do -> fluxdoctor.do"
rm -f fluxdoctor.do
# $AC -dos140 fluxdoctor.do
cp images/hello.do fluxdoctor.do
# ls -l fluxdoctor.do

echo "Compiling:"
echo "  fluxdoctor.asm -> fluxdoctor.bin"
if [[ ! -r fluxdoctor.asm ]]; then
    echo "MISSING: fluxdoctor.asm" 1>&2
    exit 1
fi
rm -f fluxdoctor.bin
dasm fluxdoctor.asm -f3 -ofluxdoctor.bin
# ls -l fluxdoctor.bin

rm -f pgm.bin
echo "Extracting binary (removing 4 byte header):"
echo "  fluxdoctor.bin -> pgm.bin"
# Get start address in hex from first two byte.
startadr="0x$(od -An -t x2 -N2 fluxdoctor.bin | tr -d ' ')"
echo "Start address: $startadr"
# Remove first four bytes (len + start)
cat fluxdoctor.bin | tail -c+5 > pgm.bin

echo "Removing existing program:"
echo "  FLUXDOCTOR"
$AC -d fluxdoctor.do FLUXDOCTOR

echo "Adding binary to disk image:"
echo "  pgm.bin -> FLUXDOCTOR"
$AC -p fluxdoctor.do FLUXDOCTOR B $startadr < pgm.bin

echo "Final disk image:"
echo "  fluxdoctor.do"
$AC -ll fluxdoctor.do

echo "To write image to a physical floppy using greaseweazle:"
echo "  gw write --tracks=step=2 fluxdoctor.do    # 96TPI floppy drive"
echo "  gw write fluxdoctor.do                    # 48TPI floppy drive"

os_name="$(uname -s)"
case $os_name in
  Darwin)
    # macOS
    '/Applications/Virtual ][.app/Contents/MacOS/Virtual ][' fluxdoctor.do
    ;;
  Linux)
    # Linux
    echo "TODO: launch emulator with disk image: fluxdoctor.do"
    ;;
  MINGW64*)
    # Windows Git Bash
    echo "Launching AppleWin emulator"
    AppleWin -d1 fluxdoctor.do
    ;;
  *)
    echo "ERROR: Unknown OS name for `$os_name`" 1>&2
    ;;
esac
