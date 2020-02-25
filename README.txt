Fallout 4 and Fallout 76 sfx and music conversion kit for PC.

Steps:
Step 1) -> this takes the longest and most manual work. This will generate a lot of Gigabytes of data!
Download BAE tool here  https://www.nexusmods.com/fallout4/mods/78/?
Make a folder for file extraction, for example "C:\Extracted"

Browse to the Fallout 4 or Fallout 76 Intallation folders.
This depends if you use the Bethesda launcher or Steam for each game.
Currently, FO4 is only available on Steam. FO76 is only available through the Bethesda launcher.
FO76 will be available on Steam from April 2020.

Anyway, nativate for each game to the <install folder>\Data.
Locate each *.ba2 files.
For FO76, you want the files:
- SeventySix - Sounds01.ba2
- SeventySix - Sounds02.ba2
- SeventySix - Voices.ba2
- SeventySix - Startup.ba2
- SeventySix - ??UpdateStream.ba2  (Where ?? is a double number from 00, 01, 02 to .. for each update)

Extract with BAE for each ba2 file, the sounds and music packed folders.
For each ba2 file, i create a sub folder with the same name under "C:\Extracted".

Step 2)  -> prepare for conversion of xmp files to wav/mp3
Copy convert_wav_to_mp3.ps1 and convert_xwm_to_wav.ps1 to "C:\Extracted"
Make a subfolder "C:\Extracted\ffmpeg"
Make a subfolder "C:\Extracted\xWMAEncode"

Download xWMAEncode.exe to "C:\Extracted\xWMAEncode" from https://www.nexusmods.com/skyrim/mods/32075/?tab=files
Download ffmpeg static for Windows to "C:\Extracted\ffmpeg" from https://ffmpeg.zeranoe.com/builds/

Step 3)  -> follow each step as described. This will generate a lot of Gigabytes of data!
Start powershell
Set-Location C:\Extracted
.\convert_xwm_to_wav.ps1    <- this converts all *.xmp to *.wav files (raw)
.\convert_wav_to_mp3.ps1    <- this converts all *.wav to *.mp3 files (compressed)


Have fun,
Pieter De Ridder
