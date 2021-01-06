
#
# Pieter De Ridder
# Script to convert fuz (Skyrim Fuze) to xwm (xWMA) in a loop
# created : 05/01/2021
# updated : 06/01/2021
#
# Usage:
# .\convert_fuz_to_xwm.ps1 [-CustomDir <custom_path_directory>]
#

# Global vars
$global:WorkingDir = $($PSScriptRoot)
$global:WorkingDirFuzDecode = "$($global:WorkingDir)\fuze"
$global:FuzDecode = "$($global:WorkingDirFuzDecode)\BmlFuzDecode.exe"


#
# Function : Convert-ToFuz
# Convert fuz file to xwm with BmlFuzDecode
#
Function Convert-ToFuz {

    Param(
        [string]$FuzFile
    )

    If (Test-Path -Path $global:FuzDecode) {
        If (Test-Path -Path $FuzFile) {
            If ($FuzFile.EndsWith(".fuz")) {
                $sOutputPath = Split-Path $FuzFile -Parent

                $sOutputFile = (Split-Path $FuzFile -Leaf)
                $sOutputFile = $sOutputFile.Substring(0, ($sOutputFile.Length -3)) + "xwm"

                $sOutput = "$($sOutputPath)\$($sOutputFile)"

                If (-not (Test-Path $sOutput)) {
                    $sProcArgs = "$([char]34)$($FuzFile)$([char]34) $([char]34)$($sOutput)$([char]34)"
                    #$arrProcArgs = @()
                    #$arrProcArgs += "$([char]34)$($FuzFile)$([char]34)"
                    #$arrProcArgs += "$([char]34)$($sOutput)$([char]34)"

                    Write-Host "Generating $($sOutputFile)..."
                    #$p = Start-Process -FilePath $global:FuzDecode -WorkingDirectory $global:WorkingDirFuzDecode -ArgumentList $arrProcArgs -NoNewWindow -Wait -PassThru

                    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                    $pinfo.FileName = $global:FuzDecode
                    $pinfo.WorkingDirectory = $global:WorkingDirFuzDecode
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
                        Write-Warning "Fuze Decode : success"
                    } else {
                        Write-Warning "Fuze Decode : failed? [Exitcode $($p.ExitCode)]"
                    }
                } else {
                    Write-Warning "$([char]34)$($sOutput)$([char]34) already exists."
                }
            } else {
                Write-Warning "$([char]34)$($FuzFile)$([char]34) not a fuze file?"
            }
        }
    } else {
        Write-Warning "BmlFuzDecode missing?!"
    }
}


#
# Function : Convert-FuzBulk 
# Convert fuz files in bulk to xwm
#
Function Convert-FuzBulk  {
    Param (
        [string]$Root
    )

    Write-Host "Bulk converting Skyrim fuze files to xwm."
    Write-Host "Indexing files in $($Root)..."

    If (Test-Path $Root) {
        $arrFuzFiles = @((Get-ChildItem -Path "$($Root)" -File -Filter *.fuz -Recurse).FullName)
        
        If ($arrFuzFiles.Length -gt 0) {
            Write-Host "Starting conversion of files..."
            ForEach($FuzFile in $arrFuzFiles) {
                Convert-ToFuz -FuzFile $FuzFile
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
# convert all fuz (Skyrim Fuze files) files in folder 'in-place' to xwm files.
# .fuz files get converted, serial wise a.k.a. synchronious, to .xwm.
# the output xwm file is placed next to the existing fuz file.
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

    Convert-FuzBulk -Root $MyExtractionFolder

    Exit(0)
}



# --- MAIN ---
Main -Arguments $args
