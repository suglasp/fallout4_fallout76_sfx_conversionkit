## Fallout 4 and Fallout 76 sound (sfx) and music Powershell conversion kit for PC.

-----

**What is does**

Toolkit that reads Fallout 4 or 76 game files, and extracts the audio/sound/music/sfx
to a folder on your local computer/disk.

-----

**Notice**

This code or kit has nothing to do with Bethesda Softworks/Microsoft/Zenimax,
and is only a small project I work on during my free hours.
Secondly, this tool does not change or edit anything to the game files.
It only reads the game data files and extracts data from within the compressed/archived files.

-----

**Conversion kit updates, fixes and patches**

Update 19/03/2020:
- 'fo76_ba2_archive_extract_sounds.ps1' is a backport of script 'fo76_ba2_archive_extracter_early_test.ps1'.
The first one extracts only sound files (*.xwm and *.fuz files). The latter extracts all files from a 'General BA2' Archive type of files.
- There are 3 Fallout BA2 known archive types:
1. GNRL = General Archive  -> supported to unpack
2. DX10 = Textures Archive -> unsupported to unpack
3. GNMF = PS4 Archive      -> unsupported to unpack

Update 22/04/2020:
- Since Wastelanders update for Fallout 76, ba2 archives with voice files (like for example "SeventySix - Voices".ba2) do not contain xWMA (*.xwm) formats anymore, but the Skyrim Fuze (*.fuz) format.
Fuze files (*.fuz) are actually a format with xWMA data and also include lipsync meta data (*.lip).
In fact, a fuze file, is a file with two combined files stitched together.

Update 05/01/2020:
- Made some small fixes to the script.
- Main functions arguments where not passed.
- Arguments datatype is now pre-defined as string array
- Extract path used a dot notation (Powershell), changed this so the script fill's in full path. Extract would fail to the Windows System folder when ran with a standard powershell startup shell.
- Now extracts the *.fuz files and *.xwm files
- Added new script convert_fuz_to_xwm.ps1 to convert fuz to xwm files.
- Convert scripts now start conversion tools with High priority, for faster processing.

Update 06/01/2020:
- Convert scripts now support a custom path through the parameter -CustomDir <dir>
- Script "convert_wav_to_mp3.ps1" got a bug that didn't trigger ffmpeg.exe
- Updated comments in scripts with info how to run scripts and optional parameters.

Update 07/01/2020:
- The sfx extract script, fo76_ba2_archive_extract_sounds.ps1, will now auto include <Fallout install path>\Data when a custom path is entered.
- Added -help parameter for cli help

Update 11/01/2021:
- Improved Fallout default game installation path checking in the main script(s)
- Fixed a few typo's in comments

Update 04/10/2021:
- Small optimization in code.

Update 22/02/2022 (NOTICE):
- Bethesda.net launcher will be retired between April-May 2022. After that time, i will update the scripts to point default to the Steam version.

Update 11/01/2023:
- Changed routine to hunt down install paths for FO4, FO76, FO76PTS.
  Bethesda.net launcher code is removed and also the "fixed" Steam installer locations.
  The code now hunts down the paths from Valve Steam installer locations in Windows registry. (*)
  (*) I've noticed, if you install a game in Steam, and later move it to an other Game Library in your Steam account,
      Steam does not update the installation path of the moved game in Windows Registry. This is a bug in Steam.
      In this case, fo76_ba2_archive_extract_sounds.ps1 will give you a warning the game path is not found.
      To fix this, you need to use .\fo76_ba2_archive_extract_sounds.ps1 -InstallPath "<driveletter>:\SteamLibrary\steamapps\common\<game_name>\".

Update 14/01/2023:
- Script 'convert_fuz_to_xwm.ps1' is rewritten, so it does not need any 3rd party tools for extracting xwm data from all Fuze files.
  The "fuze" subfolder and utility BmlFuzDecode.exe are made obsolete in order for the script to work.

Update 29/09/2023:
- Since a recent update of the FO76 ba2 archives, most "SeventySix - Interface*.ba2" files, localization and Miscclient archives only
  returned a single file. Powershell converts this to System.String instead of System.Array (or System.Collections.Array).
  This spawned sometimes errors while extracting.
- Refactored small pieces of code and made some DataType improvements.
- Did some research on the xwm file format. Seems to be a very specific format of the WMA Pro/WMA2 file format. Created for Xbox.
  Only the FFMpeg open source project supports this data type. The once leaked W2K3 code, contains parts of early code for the format.
  Technically, we could try to write or convert it natively in Powershell/.NET. But in the end it will be more error prone
  to write this code and cost me lots of time reversing it. The header of xwm files, are quite simple RIFF format headers.
  So I decided to stick with FFMpeg to decode and convert the xwm files to wave.

-----

**In high level overview, these are the steps we do**

- Search inside the *.ba2 Fallout archive files for *.xwm (or now more recent also *.fuz) files.
- Extract these files and write to disk.
- Run a second tool to convert the *.fuz files to *.xwm.
- Run a third tool to convert the *.xwm files to RIFF (wav files) - relies on FFMpeg.
- Run a fourth tool to convert the *.wav files to mp3 [optional] - relies on FFMpeg.

----

**Future project steps**

- (done) Include Powershell code for in bulk, read and extract *.fuz files natively in Powershell.
         Container format that holds .lip + .xwm and extract the xmw file data.
- (skip) Include Powershell code for in bulk, read and decode *.xwm files natively in Powershell.
         Same format as Microsoft XAudio2 xWMA format, and convert it to wav files.
- (todo) Make it so, if we detect Powershell version 7+, we process in parallel.

-----

**Current method to extract**

Steps:
1. This step takes the longest. This will generate a lot of Gigabytes of data!
Download the Extraction tool [here](https://github.com/suglasp/fallout4_fallout76_sfx_conversionkit/blob/master/fo76_ba2_archive_extract_sounds.ps1) or download the [B.E.A. Tool](https://www.nexusmods.com/fallout4/mods/78/?).

Parameters (optional):

`.\fo76_ba2_archive_extract_sounds.ps1 [-InstallPath <fallout4_fallout76_installpath>] [-Fallout "Fallout4"|"Fallout76"|"Fallout76PTS"] [-ExtractDir <extract_dir>]`

Open powershell and run `.\fo76_ba2_archive_extract_sounds.ps1 -Fallout <FO_game_you_want> -ExtractDir <folder_to_extract>`.

Default, the script will search in the Steam installation folders it finds in Windows Registry.
If you installed FO4 of FO76 in a custom path, use the flag `.\fo76_ba2_archive_extract_sounds.ps1 -InstallPath <path>`.
The script above will search all *.ba2 files, and will start extracting all *.xwm files or *.fuz files automatically.

Default, the script will target 'Fallout76'. If you want Fallout 4 or Fallout 76 PTS,
then use the flag `.\fo76_ba2_archive_extract_sounds.ps1 -Fallout "Fallout4"` or `.\fo76_ba2_archive_extract_sounds.ps1 -Fallout "Fallout76PTS"`.

Default, the script will create a subfolder "extracted_sfx" in the folder from where it is ran.
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


2. Prepare for conversion of xwm files to wav/mp3
Copy convert_wav_to_mp3.ps1, convert_fuz_to_xwm.ps1 and convert_xwm_to_wav.ps1 to the extract folder.
- Make a subfolder "ffmpeg"
- Make a subfolder "xWMAEncode"
- Download [xWMAEncode.exe](https://www.nexusmods.com/skyrim/mods/32075/?tab=files) or [xWMAEncode.exe](https://www.microsoft.com/en-ca/download/details.aspx?id=6812) to the folder "xWMAEncode" and extract to folder "xWMAEncode".
- Download [ffmpeg](https://ffmpeg.org/download.html#build-windows) static compiled for Windows to "ffmpeg" and extract to folder "ffmpeg". (*)

(*) Inside the "ffmpeg" folder, there needs to be a "bin" folder (so, ..\ffmpeg\bin) where you put the ffmpeg.exe file.


3. follow each step as described. This will generate a lot of Gigabytes of data!
- `Start powershell`
- `Set-Location <path_of_ExtractDir>` (see above with fo76_ba2_archive_extract_sounds.ps1)
- `.\convert_fuz_to_xwm.ps1`    <- this converts all *.fuz to *.xwm files (raw)
- `.\convert_xwm_to_wav.ps1`    <- this converts all *.xwm to *.wav files (raw)
- `.\convert_wav_to_mp3.ps1`    <- this converts all *.wav to *.mp3 files (compressed)  [optional]

Parameters (optional):
`.\convert_XXX_to_XXX.ps1 [-CustomDir <custom_path_dir>]`



Have fun,
Pieter De Ridder aka Suglasp
