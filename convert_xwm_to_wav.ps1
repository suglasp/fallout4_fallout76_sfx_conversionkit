
#
# Pieter De Ridder
# Script to convert Xwm (xMWA) to wav (RIFF) in a loop
# created : 25/02/2020
# updated : 06/01/2021
#
# Usage:
# .\convert_xwm_to_wav.ps1 [-CustomDir <custom_path_directory>]
#

# Global vars
$global:WorkingDir = $($PSScriptRoot)
$global:WorkingDirxWMAEnc = "$($global:WorkingDir)\xWMAEncode"
$global:xWMAEnc = "$($global:WorkingDirxWMAEnc)\xWMAEncode.exe"


#
# Function : Convert-ToWav
# Convert xwm file to wav with xWMAEncode
#
Function Convert-ToWav {

    Param(
        [string]$XwmFile
    )

    If (Test-Path -Path $global:xWMAEnc) {
        If (Test-Path -Path $XwmFile) {
            If ($XwmFile.EndsWith(".xwm")) {
                $sOutputPath = Split-Path $XwmFile -Parent

                $sOutputFile = (Split-Path $XwmFile -Leaf)
                $sOutputFile = $sOutputFile.Substring(0, ($sOutputFile.Length -3)) + "wav"

                $sOutput = "$($sOutputPath)\$($sOutputFile)"

                If (-not (Test-Path $sOutput)) {
                    $sProcArgs = "$([char]34)$($XwmFile)$([char]34) $([char]34)$($sOutput)$([char]34)"
                    #$arrProcArgs = @()
                    #$arrProcArgs += "$([char]34)$($XwmFile)$([char]34)"
                    #$arrProcArgs += "$([char]34)$($sOutput)$([char]34)"

                    Write-Host "Generating $($sOutputFile)..."
                    #$p = Start-Process -FilePath $global:xWMAEnc -WorkingDirectory $global:WorkingDirxWMAEnc -ArgumentList $arrArgs -NoNewWindow -Wait -PassThru
                    
                    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                    $pinfo.FileName = $global:xWMAEnc
                    $pinfo.WorkingDirectory = $global:WorkingDirxWMAEnc
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
                        Write-Warning "xWMAEnc : success"
                    } else {
                        Write-Warning "xWMAEnc : failed? [Exitcode $($p.ExitCode)]"
                    }
                } else {
                    Write-Warning "$([char]34)$($sOutput)$([char]34) already exists."
                }
            } else {
                Write-Warning "$([char]34)$($XwmFile)$([char]34) not a xwm file?"
            }
        }
    } else {
        Write-Warning "xWMAEncode missing?!"
    }
}


#
# Function : Convert-XwmBulk 
# Convert xwm files in bulk to wav
#
Function Convert-XwmBulk  {
    Param (
        [string]$Root
    )

    Write-Host "Bulk converting xmp files to wav."
    Write-Host "Indexing files in $($Root)..."

    If (Test-Path $Root) {
        $arrXwmFiles = @((Get-ChildItem -Path "$($Root)" -File -Filter *.xwm -Recurse).FullName)
        
        If ($arrXwmFiles.Length -gt 0) {
            Write-Host "Starting conversion of files..."
            ForEach($XwmFile in $arrXwmFiles) {
                Convert-ToWav -XwmFile $XwmFile
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
# convert all xmp files in folder 'in-place' to wav files.
# .xmp files get converted, serial wise a.k.a. synchronious, to .wav.
# the output wav file is placed next to the existing xmp file.
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

            # default, a PWSH Switch statement on a String is always case insenstive
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

    Convert-XwmBulk -Root $MyExtractionFolder

    Exit(0)
}


# --- MAIN ---
Main -Arguments $args
