
#
# Pieter De Ridder
# Script to convert wav (RIFF) to mp3 (Compressed) in a loop
# https://github.com/suglasp/pwsh_convert_wav_to_mp3
# created : 25/02/2020
# updated : 22/01/2023
#
# Usage:
# .\convert_wav_to_mp3.ps1 [-CustomDir <custom_path_directory>]
#

# Global vars
$Global:WorkingDir = "$($PSScriptRoot)"
$Global:WorkingDirFFMPEG = "$($Global:WorkingDir)\ffmpeg\bin"
$Global:ffmpeg = "$($Global:WorkingDirFFMPEG)\ffmpeg.exe"


#
# Function : Convert-ToWav2MP3
# Convert wav file to mp3 with ffmpeg.exe.
# Supports ffmpeg.exe version 3.x.
#
Function Convert-ToWav2MP3 {

    Param(
        [string]$WAVFile
    )

    If (Test-Path -Path $Global:ffmpeg) {
        If (Test-Path -Path $WAVFile) {
            If ($WAVFile.EndsWith(".wav")) {
                [String]$sOutputPath = Split-Path $WAVFile -Parent

                [String]$sOutputMp3File = (Split-Path $WAVFile -Leaf)
                $sOutputMp3File = $sOutputMp3File.Substring(0, ($sOutputMp3File.Length -3)) + "mp3"

                [String]$sOutputMp3 = "$($sOutputPath)\$($sOutputMp3File)"

                If (-not (Test-Path -Path $sOutputMp3)) {
                    $sProcArgs = "-i $([char]34)$($WAVFile)$([char]34) -vn -ar 44100 -ac 2 -b:4 192k $([char]34)$($sOutputMp3)$([char]34) -hwaccels"
                    #$arrProcArgs = @()
                    #$arrProcArgs += "-i"   # input filename
                    #$arrProcArgs += "$([char]34)$($WAVFile)$([char]34)"
                    #$arrProcArgs += "-vn"  # -v log level and -n never overwrite output files
                    #$arrProcArgs += "-ar"   # sound rate of 44100Hz
                    #$arrProcArgs += "44100" 
                    #$arrProcArgs += "-ac"   # 2 channels
                    #$arrProcArgs += "2"
                    #$arrProcArgs += "-b:a"  # bitrate of 192K
                    #$arrProcArgs += "192k"  
                    #$arrProcArgs += "$([char]34)$($sOutputMp3)$([char]34)"  # output filename
                    #$arrProcArgs += "-hwaccels"  # optional, enable HW acceleration if available

                    Write-Host "Generating $($sOutputMp3File)..."
                    #$p = Start-Process -FilePath $Global:ffmpeg -WorkingDirectory $Global:WorkingDirFFMPEG -ArgumentList $arrProcArgs -NoNewWindow -Wait -PassThru
                    
                    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                    $pinfo.FileName = $Global:ffmpeg
                    $pinfo.WorkingDirectory = $Global:WorkingDirFFMPEG
                    $pinfo.Arguments = $sProcArgs
                    $pinfo.CreateNoWindow = $true
                    $pinfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
                    $pinfo.RedirectStandardError = $true
                    $pinfo.RedirectStandardOutput = $true
                    $pinfo.UseShellExecute = $false                  
                 
                    $p = New-Object System.Diagnostics.Process
                    $p.StartInfo = $pinfo
                    $p.Start() | Out-Null
                    $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                    $p.WaitForExit()

                    if ($p.ExitCode -eq 0) {
                        Write-Warning "mp3 conversion : success"
                    } Else {
                        Write-Warning "mp3 conversion : failed? [Exitcode $($p.ExitCode)]"
                    }
                } Else {
                    Write-Warning "$([char]34)$($sOutputMp3)$([char]34) already exists."
                }
            } Else {
                Write-Warning "$([char]34)$($WAVFile)$([char]34) not a wav file?"
            }
        }
    } Else {
        Write-Warning "FFMPEG missing?!"
    }
}


#
# Function : Convert-WavBulk 
# Convert wave files in bulk to mp3
#
Function Convert-WavBulk {
    Param (
        [string]$Root
    )

    Write-Host "Bulk converting wav files to mp3."
    Write-Host "Indexing files in $($Root)..."

    If (Test-Path $Root) {
        $arrWavFiles = @((Get-ChildItem -Path "$($Root)" -File -Filter *.wav -Recurse).FullName)
        
        If ($arrWavFiles.Length -gt 0) {
            Write-Host "Starting conversion of files..."
            ForEach($WavFile In $arrWavFiles) {
                Convert-ToWav2MP3 -WAVFile $WavFile
            }
        } Else {
            Write-Warning "No files found?"
        }
    } Else {
        Write-Warning "$($Root) path not found?"
    }
}

#
# Function : Main
# Main function
#
#
# convert all wav files in folder 'in-place' to mp3 files.
# .wav files get converted, serial wise a.k.a. synchronious, to .mp3.
# the output mp3 file is placed next to the existing wav file.
#
Function Main {

    Param (
        [string[]]$Arguments
    )

    [string]$MyExtractionFolder = "$($Global:WorkingDir)\extracted_sfx"  # extraction folder
     
    # logic for cmdline arguments
    If ($Arguments) {
        For($i = 0; $i -lt $Arguments.Length; $i++) {
            #Write-Host "DEBUG : Arg $($i.ToString()) is $($Arguments[$i])"

            # default, a PWSH Switch statement on a String is always case insensitive
            Switch ($Arguments[$i]) {
                "-CustomDir" {
                    # manually override extraction folder
                    If (($i +1) -le $Arguments.Length) {
                        $MyExtractionFolder = $Arguments[$i +1]
                    }

                    # remove trailing backslash if needed
                    If ($MyExtractionFolder.EndsWith('\')) {
                        $MyExtractionFolder = $MyExtractionFolder.Substring(0, $MyExtractionFolder.Length -1)
                    }
                }
            }             
        }
    }

    Convert-WavBulk -Root $MyExtractionFolder

    Exit(0)
}


# --- MAIN ---
Main -Arguments $args
