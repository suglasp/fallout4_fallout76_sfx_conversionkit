Fallout 4 and Fallout 76 sfx and music conversion kit for PC.

-----
Optional update 15/03/2020:
I've included a script 'fo76_ba2_archive_extracter_early_test.ps1' that can extract BA2 archive files.
Currently it works to extract all *.xmp files (= SFX files) from the ba2 archives.
Compressed files are mostly ZLib or LZ4 compression. I've been testing with ZLib (DeflateStream in .NET),
but this seems not to correctly decompress those files.
-----

Steps:
Step 1) -> this takes the longest and is the most manual work. This will generate a lot of Gigabytes of data!
Download BAE tool here  https://www.nexusmods.com/fallout4/mods/78/?
Make a folder for file extraction, for example "C:\Extracted"

Browse to the Fallout 4 or Fallout 76 Intallation folders.
This depends if you use the Bethesda launcher or Steam for each game.
Currently, FO4 is only available on Steam. FO76 is only available through the Bethesda launcher.
(FO76 will be available on Steam from April 2020 when Wastelanders arrive.)

Any way, navigate for each game to the <install folder>\Data.
Locate each *.ba2 compressed game files.

For FO76, you want these files for sfx/music:
- SeventySix - Sounds01.ba2
- SeventySix - Sounds02.ba2
- SeventySix - Voices.ba2
- SeventySix - Startup.ba2
- SeventySix - ??UpdateStream.ba2  (Where ?? is a double number from 00, 01, 02 to .. for each update)

For FO4, you want these files for sfx/music:
- Fallout4 - Sounds.ba2

Extract with BAE for each ba2 file, the sounds and music packed folders.
For each ba2 file, i create a sub folder with the same name under "C:\Extracted".

Step 2)  -> prepare for conversion of xmp files to wav/mp3
Copy convert_wav_to_mp3.ps1 and convert_xwm_to_wav.ps1 to "C:\Extracted"
Make a subfolder "C:\Extracted\ffmpeg"
Make a subfolder "C:\Extracted\xWMAEncode"

Download xWMAEncode.exe to "C:\Extracted\xWMAEncode" from https://www.nexusmods.com/skyrim/mods/32075/?tab=files
Download ffmpeg static compiled for Windows to "C:\Extracted\ffmpeg" from https://ffmpeg.zeranoe.com/builds/

Step 3)  -> follow each step as described. This will generate a lot of Gigabytes of data!
Start powershell
Set-Location C:\Extracted
.\convert_xwm_to_wav.ps1    <- this converts all *.xmp to *.wav files (raw)
.\convert_wav_to_mp3.ps1    <- this converts all *.wav to *.mp3 files (compressed)


Have fun,
Pieter De Ridder aka Suglasp