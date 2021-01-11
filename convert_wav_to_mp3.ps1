
#
# Pieter De Ridder
# Script to convert wav (RIFF) to mp3 (Compressed) in a loop
# created : 25/02/2020
# updated : 11/01/2021
#
# Usage:
# .\convert_wav_to_mp3.ps1 [-CustomDir <custom_path_directory>]
#

# Global vars
$global:WorkingDir = $($PSScriptRoot)
$global:WorkingDirFFMPEG = "$($global:WorkingDir)\ffmpeg\bin"
$global:ffmpeg = "$($global:WorkingDirFFMPEG)\ffmpeg.exe"


#
# Function : Convert-ToMP3
# Convert wav file to mp3 with ffmpeg.exe 
#
Function Convert-ToMP3 {

    Param(
        [string]$WAVFile
    )

    If (Test-Path -Path $global:ffmpeg) {
        If (Test-Path -Path $WAVFile) {
            If ($WAVFile.EndsWith(".wav")) {
                $sOutputPath = Split-Path $WAVFile -Parent

                $sOutputFile = (Split-Path $WAVFile -Leaf)
                $sOutputFile = $sOutputFile.Substring(0, ($sOutputFile.Length -3)) + "mp3"

                $sOutput = "$($sOutputPath)\$($sOutputFile)"

                If (-not (Test-Path $sOutput)) {
                    $sProcArgs = "-i $([char]34)$($WAVFile)$([char]34) -vn -ar 44100 -ac 2 -b:4 192k $([char]34)$($sOutput)$([char]34)" 
                    #$arrProcArgs = @()
                    #$arrProcArgs += "-i" 
                    #$arrProcArgs += "$([char]34)$($WAVFile)$([char]34)"
                    #$arrProcArgs += "-vn" 
                    #$arrProcArgs += "-ar" 
                    #$arrProcArgs += "44100" 
                    #$arrProcArgs += "-ac"
                    #$arrProcArgs += "2"
                    #$arrProcArgs += "-b:a"
                    #$arrProcArgs += "192k"
                    #$arrProcArgs += "$([char]34)$($sOutput)$([char]34)"

                    Write-Host "Generating $($sOutputFile)..."
                    #$p = Start-Process -FilePath $global:ffmpeg -WorkingDirectory $global:WorkingDirFFMPEG -ArgumentList $arrProcArgs -NoNewWindow -Wait -PassThru
                    
                    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                    $pinfo.FileName = $global:ffmpeg
                    $pinfo.WorkingDirectory = $global:WorkingDirFFMPEG
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
                        Write-Warning "ffmpeg : success"
                    } else {
                        Write-Warning "ffmpeg : failed? [Exitcode $($p.ExitCode)]"
                    }
                } else {
                    Write-Warning "$([char]34)$($sOutput)$([char]34) already exists."
                }
            } else {
                Write-Warning "$([char]34)$($WAVFile)$([char]34) not a wav file?"
            }
        }
    } else {
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

    Write-Host "Bulk converting wave files to mp3."
    Write-Host "Indexing files in $($Root)..."

    If (Test-Path $Root) {
        $arrWavFiles = @((Get-ChildItem -Path "$($Root)" -File -Filter *.wav -Recurse).FullName)
        
        If ($arrWavFiles.Length -gt 0) {
            Write-Host "Starting conversion of files..."
            ForEach($WavFile in $arrWavFiles) {
                Convert-ToMP3 -WAVFile $WavFile
            }
        } else {
            Write-Warning "No files found?"
        }
    } else {
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

    [string]$MyExtractionFolder = "$($PSScriptRoot)\extracted_sfx"  # extraction folder
     
    # logic for cmdline arguments
    If ($Arguments) {
        for($i = 0; $i -lt $Arguments.Length; $i++) {
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
