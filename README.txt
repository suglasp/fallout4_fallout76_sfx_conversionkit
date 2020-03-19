Fallout 4 and Fallout 76 sound (sfx) and music conversion kit for PC.

-----
Optional update 19/03/2020:
'fo76_ba2_archive_extract_sounds.ps1' is a backport of script 'fo76_ba2_archive_extracter_early_test.ps1'.
The first one extracts only sound files. The latter extracts all files from a General BA2 Archive type of files.

There are 3 formats of BA2 archives:
GNRL = General Archive  -> supported to unpack
DX10 = Textures Archive -> unsupported to unpack
GNMF = PS4 Archive      -> unsupported to unpack
-----

Steps:
Step 1) -> this takes the longest. This will generate a lot of Gigabytes of data!
Download the Extraction tool here https://github.com/suglasp/fo4_fo76_sfx_conversionkit/fo76_ba2_archive_extract_sounds.ps1    ( or download the B.E.A. Tool https://www.nexusmods.com/fallout4/mods/78/? )

Parameters (optional):
fo76_ba2_archive_extract_sounds.ps1 [-InstallPath <fallout4_fallout76_installpath>] [-Fallout "Fallout4"] [-ExtractDir <extract_dir>]


Open powershell and run .fo76_ba2_archive_extract_sounds.ps1.

Default, the script will search in the Steam or Bethesda Launcher installation folders.
If you installed FO4 of FO76 in a custom path, use the flag .fo76_ba2_archive_extract_sounds.ps1 -InstallPath <path>
The script above will search all *.ba2 files, and will start extracting all xmp files automatically.

Default, the script will target Fallout76. If you want Fallout 4,
then use the flag .fo76_ba2_archive_extract_sounds.ps1 -Fallout "Fallout4"

Default, the script will create extract folder "extracted_sfx" in the folder where it is ran.
If you want to change the extraction path, use the flag .fo76_ba2_archive_extract_sounds.ps1 -ExtractDir "<path to folder>"


For your information, the files of interest are for each game in the <install folder>\Data.

For FO76, you want these files for sfx/music:
- SeventySix - Sounds01.ba2
- SeventySix - Sounds02.ba2
- SeventySix - Voices.ba2
- SeventySix - Startup.ba2
- SeventySix - ??UpdateStream.ba2  (Where ?? is a double number from 00, 01, 02 to .. for each update)

For FO4, you want these files for sfx/music:
- Fallout4 - Sounds.ba2

The extract script will locate these automatically.
When running the script, it will index all ba2 files and start extracting all files.


Step 2)  -> prepare for conversion of xmp files to wav/mp3
Copy convert_wav_to_mp3.ps1 and convert_xwm_to_wav.ps1 to the extract folder.
Make a subfolder "ffmpeg"
Make a subfolder "xWMAEncode"

Download xWMAEncode.exe to the folder "xWMAEncode" from https://www.nexusmods.com/skyrim/mods/32075/?tab=files
Download ffmpeg static compiled for Windows to "ffmpeg" from https://ffmpeg.zeranoe.com/builds/


Step 3)  -> follow each step as described. This will generate a lot of Gigabytes of data!
Start powershell
Set-Location <path_of_ExtractDir> (see above with fo76_ba2_archive_extract_sounds.ps1)
.\convert_xwm_to_wav.ps1    <- this converts all *.xmp to *.wav files (raw)
.\convert_wav_to_mp3.ps1    <- this converts all *.wav to *.mp3 files (compressed)


Have fun,
Pieter De Ridder aka Suglasp
