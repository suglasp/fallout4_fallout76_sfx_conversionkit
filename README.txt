Fallout 4 and Fallout 76 sound (sfx) and music conversion kit for PC.

-----
Optional update 15/03/2020:
I've included a script 'fo76_ba2_archive_extracter_early_test.ps1' that can extract BA2 archive files.
Currently it works to extract all *.xmp files (= SFX files) from the ba2 archives.
Compressed files are mostly ZLib or LZ4 compression. I've been testing with ZLib (DeflateStream in .NET),
but this seems not to correctly decompress those files.

From the above script, i also created a variant 'fo76_ba2_archive_extract_sounds.ps1' that can extract exclusive the sound files.
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
