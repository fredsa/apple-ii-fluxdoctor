#!/bin/bash

set -eu

# dasm
#   https://dasm-assembler.github.io/

# Apple Commander
#   https://applecommander.github.io/ac/
AC="$HOME/ac-windows-amd64-13.1.exe"

# AppleWin
#   https://github.com/AppleWin/AppleWin

echo "Creating blank image:"
echo "  images/hello.do -> diag.do"
rm -f diag.do
# $AC -dos140 diag.do
cp images/hello.do diag.do
# ls -l diag.do

echo "Compiling:"
echo "  apple-disk-diag.dasm -> diag.bin"
rm -f diag.bin
dasm apple-disk-diag.dasm -f3 -odiag.bin
# ls -l diag.bin

rm -f pgm.bin
echo "Extracting binary (removing 4 byte header):"
echo "  diag.bin -> pgm.bin"
# Get start address in hex from first two byte.
startadr="0x$(od -An -t x2 -N2 diag.bin | tr -d ' ')"
echo "Start address: $startadr"
# Remove first four bytes (len + start)
cat diag.bin | tail -c+5 > pgm.bin

echo "Removing existing program:"
echo "  DIAG"
$AC -d diag.do DIAG

echo "Adding binary to disk image:"
echo "  pgm.bin -> DIAG"
$AC -p diag.do DIAG B $startadr < pgm.bin

echo "Final disk image:"
echo "  diag.do"
$AC -ll diag.do

AppleWin -d1 diag.do