#!/bin/bash
#
# FLUXDOCTOR V1.1
# 
set -eu

if ! type -p dasm >/dev/null 2>&1; then
    echo "ERROR, missing executable:" 1>&2
    echo "  dasm" 1>&2
    echo "" 1>&2
    echo "Please install dasm from:" 1>&2
    echo "  https://dasm-assembler.github.io/" 1>&2
    exit 1
fi

if ! type -p AppleWin >/dev/null 2>&1; then
    echo "ERROR, missing executable:" 1>&2
    echo "  AppleWin" 1>&2
    echo "" 1>&2
    echo "Please install AppleWin from:" 1>&2
    echo "  https://github.com/AppleWin/AppleWin" 1>&2
    exit 1
fi

AC="$HOME/ac-windows-amd64-13.1.exe"
if [[ ! -x "$AC" ]]; then
    echo "ERROR missing executable:" 1>&2
    echo "  $AC" 1>&2
    echo "" 1>&2
    echo "Please install Apple Commander from:" 1>&2
    echo "  https://applecommander.github.io/ac/" 1>&2
    exit 1
fi

echo "Creating blank image:"
echo "  images/hello.do -> fluxdoctor.do"
rm -f fluxdoctor.do
# $AC -dos140 fluxdoctor.do
cp images/hello.do fluxdoctor.do
# ls -l fluxdoctor.do

echo "Compiling:"
echo "  fluxdoctor.dasm -> fluxdoctor.bin"
if [[ ! -r fluxdoctor.dasm ]]; then
    echo "MISSING: fluxdoctor.dasm" 1>&2
    exit 1
fi
rm -f fluxdoctor.bin
dasm fluxdoctor.dasm -f3 -ofluxdoctor.bin
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

AppleWin -d1 fluxdoctor.do