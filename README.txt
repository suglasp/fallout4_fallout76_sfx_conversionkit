Fallout 4 and Fallout 76 sound (sfx) and music Powershell conversion kit for PC.

-----
>> conversion kit updates, fixes and patches:

Update 19/03/2020:
'fo76_ba2_archive_extract_sounds.ps1' is a backport of script 'fo76_ba2_archive_extracter_early_test.ps1'.
The first one extracts only sound files (*.xmp and *.fuz files). The latter extracts all files from a General BA2 Archive type of files.

There are 3 Fallout BA2 archives types:
GNRL = General Archive  -> supported to unpack
DX10 = Textures Archive -> unsupported to unpack
GNMF = PS4 Archive      -> unsupported to unpack

Update 22/04/2020:
Since Wastelanders update for Fallout 76, bz2 archives with voice files (like for example "SeventySix - Voices".ba2) do not contain xWMA (*.xmp) formats anymore, but the Skyrim Fuze (*.fuz) format.
Fuze files (*.fuz) are actually a format with xWMA data and also include lipsync meta data (*.lip).
In fact, a fuze file, is a file with two combined files stitched together.

Update 05/01/2020:
- Made some small fixes to the script.
- Main functions arguments where not passed.
- Arguments datatype is now pre-defined as string array
- extract path used a dot notation (Powershell), changed this so the script fill's in full path. Extract would fail to the Windows System folder when ran with a standard powershell startup shell.
- Now extracts the *.fuz files and *.xmp files
- Added new script convert_fuz_to_xmp.ps1 to convert fuz to xmp files.
- Convert scripts now start conversion tools with High priority, for faster processing.

Update 06/01/2020:
- Convert scripts now support a custom path through the parameter -CustomDir <dir>
- Script "convert_wav_to_mp3.ps1" got a bug that didn't trigger ffmpeg.exe
- Updated comments in scripts with info how to run scripts and optional parameters.

-----

>> In high level overview, these are the steps we do:
- Search inside the *.ba2 Fallout archive files for *.xmp (or now more recent also *.fuz) files.
- Extract these files and write to disk.
- Run a second tool to convert the *.fuz files to *.xmp.
- Run a third tool to convert the *.xmp files to RIFF (wav files).
- Run a fourth tool to convert the *.wav files to mp3.

----

>> Future project steps:
- Include powershell code for in bulk, read a *.xmp (xWMA format) and write it to wav file.
- Include powershell code for in bulk, read a *.fuz (special xWMA format) and write it to wav file.
- Make it so, if we detect Powershell version 7+, we process in parallel.

-----

>> Current method to extract:

Steps:
Step 1) -> this takes the longest. This will generate a lot of Gigabytes of data!
Download the Extraction tool here https://github.com/suglasp/fo4_fo76_sfx_conversionkit/fo76_ba2_archive_extract_sounds.ps1    ( or download the B.E.A. Tool https://www.nexusmods.com/fallout4/mods/78/? )

Parameters (optional):
fo76_ba2_archive_extract_sounds.ps1 [-InstallPath <fallout4_fallout76_installpath>] [-Fallout "Fallout4"|"Fallout76"] [-ExtractDir <extract_dir>]


Open powershell and run .\fo76_ba2_archive_extract_sounds.ps1.

Default, the script will search in the Steam or Bethesda Launcher installation folders.
If you installed FO4 of FO76 in a custom path, use the flag .\fo76_ba2_archive_extract_sounds.ps1 -InstallPath <path>
The script above will search all *.ba2 files, and will start extracting all *.xmp files or *.fuz files automatically.

Default, the script will target 'Fallout76'. If you want Fallout 4,
then use the flag .\fo76_ba2_archive_extract_sounds.ps1 -Fallout "Fallout4".

Default, the script will create a subfolder "extracted_sfx" in the folder where it is ran.
If you want to change the extraction path, use the flag .\fo76_ba2_archive_extract_sounds.ps1 -ExtractDir "<full path to folder>"


For your information, the files of interest are for each Fallout[4|76] game in the "<game install folder>\Data".

For FO76, you want mainly these files for sfx/music extraction:
- SeventySix - Sounds01.ba2
- SeventySix - Sounds02.ba2
- SeventySix - Voices.ba2
- SeventySix - Startup.ba2
- SeventySix - ??UpdateStream.ba2  (Where ?? is a double number from 00, 01, 02 to .. for each Fallout 76 released Bethesda patch)

For FO4, you want these files for sfx/music:
- Fallout4 - Sounds.ba2

The extract script will locate the archive files automatically.
When running the script, it will index all *.ba2 files and start extracting all files.


Step 2)  -> prepare for conversion of xmp files to wav/mp3
Copy convert_wav_to_mp3.ps1, convert_fuz_to_xmp.ps1 and convert_xwm_to_wav.ps1 to the extract folder.
Make a subfolder "ffmpeg"
Make a subfolder "xWMAEncode"
Make a subfolder "fuze"

Download BmlFuzDecode.exe to the folder "fuze" from https://www.nexusmods.com/skyrim/mods/73100/ (download BmlFuzTools and extract the zip file. Copy *.exe files to "fuze" folder).
Download xWMAEncode.exe to the folder "xWMAEncode" from https://www.nexusmods.com/skyrim/mods/32075/?tab=files and extract to folder "xWMAEncode".
Download ffmpeg static compiled for Windows to "ffmpeg" from https://ffmpeg.org/download.html#build-windows and extract to folder "ffmpeg". (*)

(*) Inside the "ffmpeg" folder, there needs to be a "bin" folder (so, ..\ffmpeg\bin) where you put the ffmpeg.exe file.


Step 3)  -> follow each step as described. This will generate a lot of Gigabytes of data!
Start powershell
Set-Location <path_of_ExtractDir> (see above with fo76_ba2_archive_extract_sounds.ps1)
.\convert_fuz_to_xmp.ps1    <- this converts all *.fuz to *.xmp files (raw)
.\convert_xwm_to_wav.ps1    <- this converts all *.xmp to *.wav files (raw)
.\convert_wav_to_mp3.ps1    <- this converts all *.wav to *.mp3 files (compressed)

Parameters (optional):
convert_XXX_to_XXX.ps1 [-CustomDir <custom_path_dir>]


Have fun,
Pieter De Ridder aka Suglasp
