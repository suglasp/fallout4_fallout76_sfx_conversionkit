
#
# Pieter De Ridder
# Script to convert wav to mp3 in a loop
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

    If (Test-Path $global:ffmpeg) {
        If (Test-Path $WAVFile) {
            If ($WAVFile.EndsWith(".wav")) {
                $sOutputPath = Split-Path $WAVFile -Parent

                $sOutputFile = (Split-Path $WAVFile -Leaf)
                $sOutputFile = $sOutputFile.Substring(0, ($sOutputFile.Length -3)) + "mp3"

                $sOutput = "$($sOutputPath)\$($sOutputFile)"

                If (-not (Test-Path $sOutput)) {
                    $arrArgs = @()
                    $arrArgs += "-i" 
                    $arrArgs += "$([char]34)$($WAVFile)$([char]34)"
                    $arrArgs += "-vn" 
                    $arrArgs += "-ar" 
                    $arrArgs += "44100" 
                    $arrArgs += "-ac"
                    $arrArgs += "2"
                    $arrArgs += "-b:a"
                    $arrArgs += "192k"
                    $arrArgs += "$([char]34)$($sOutput)$([char]34)"

                    Write-Host "Generating $($sOutputFile)..."
                    $p = Start-Process -FilePath $global:ffmpeg -WorkingDirectory $global:WorkingDirFFMPEG -ArgumentList $arrArgs -NoNewWindow -Wait -PassThru
                
                    if ($p.ExitCode -eq 0) {
                        Write-Warning "ffmpeg : success"
                    } else {
                        Write-Warning "ffmpeg : failed?"
                    }
                } else {
                    Write-Warning "$($sOutput) already exists."
                }
            } else {
                Write-Warning "$($WAVFile) not a wav file?"
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
# convert all wav files in folder 'in-place' to mp3 files.
# .wav files get converted, serial wise a.k.a. synchronious, to .mp3.
# the output mp3 file is placed next to the existing wav file.
#
Convert-WavBulk -Root ".\"
