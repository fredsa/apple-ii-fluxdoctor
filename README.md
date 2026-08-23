# **`FLUXDOCTOR`** V1.2 for Apple II computers

Diagnostic utility for real-time troubleshooting, calibration, and repair of
Apple II floppy disks drives. Runs natively on Apple II computer hardware.

- Drive spins indefinitely by default for easy troubleshooting
- Autostarts, no keyboard required to diagnose floppy drive read performance
- Provides direct low-level control to stop/start motor and seek heads
- Real-time display of sector read performance and errors
- Exposes weak reads and subtle intermittent errors hidden by DOS
- Distinguishes seek, checksum, and sector prologue/epilogue errors
- Can be used to diagnose poorly written or misaligned floppy disk drives

Available as a bootable (140kB) DOS 3.3 floppy disk image (`*.DO`) from the
**Releases** page.

<img width="50%" height="50%" src="fluxdoctor.png">

`FLUXDOCTOR` requires a DOS 3.3 environment as it utilizes DOS `RWTS` routines
for track seeks. All other functions are performed by accessing the hardware
directly directly from 6502 assembly.


# Build prerequisites

To build FLUXDOCTOR from source, you'll need the following:

1. To be able to compile FLUXDOCTOR from source, install **dasm** assembler from
   https://dasm-assembler.github.io/

3. To manipulate disk images and add the compiled `FLUXDOCTOR` binary to a
   DOS 3.3 disk image, install **AppleCommander** from
   https://applecommander.github.io/ac/

4. (Windows only) To be able to run in the provided shell scripts, install
   [Git BASH](https://gitforwindows.org/), or install
   [Windows Subsystem for Linux (WSL)](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)


# Build instructions

To build FLUXDOCTOR, run the provied bash script:

```
./run.sh
```

# Writing physical floppy disks

To make a physical FLUXDOCTOR floppy disk, you have a few options:

## Greaseweazle

Purchase a [Greaseweazle](https://github.com/keirf/greaseweazle). Use the `gw`
command to write the 35-track 140kB `fluxdoctor.do` DOS 3.3 floppy disk image
using any PC or Shutgart 5.25" floppy drive to a double density floppy diskL

```
# Specify `--tracks=step=2` if your using a 96TPI drive.
gw write --tracks=step=2 fluxdoctor-*.do
```

## ADTPro

Use [ADTPro](https://github.com/ADTPro/adtpro) to write physical disk images
using your Apple II system, using an audio cable and cassette port on your
Apple II.

## c2t

Use [c2t](https://github.com/datajerk/c2t), the same tool that powers
https://asciiexpress.net/ to create a WAV file you can just send to your
Apple II using an audio cable. Works even if you don't (yet) have a bootable
floppy disk.

To compile `c2t.exe` on Windows, install the
[MSYS2](https://www.msys2.org/docs/environments/) `UCRT64` environment.

Use `c2t` to create the WAV file which you can stream to your Apple II cassette
port:

```
cp fluxdoctor.do fluxdoctor.dsk
c2t fluxdoctor.dsk fluxdoctor.wav
```


# Testing

During development it's not always convenient to test on real hard. There are
many suitable Apple II emulators available, see:
   - Web browser: [appleiijs](https://www.scullinsteel.com/apple2/) /
     [appleiijse](https://www.scullinsteel.com/apple//e)
   - Linux / macOS: see
     https://en.wikipedia.org/wiki/List_of_computer_system_emulators#Apple_II
   - Windows: **AppleWin** from https://github.com/AppleWin/AppleWin
