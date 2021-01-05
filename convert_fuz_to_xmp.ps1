
#
# Pieter De Ridder
# Script to convert fuz (Skyrim Fuze) to xmp (xWMA) in a loop
# created : 05/01/2021
# updated : 05/01/2021
#

# Global vars
$global:WorkingDir = $($PSScriptRoot)
$global:WorkingDirFuzDecode = "$($global:WorkingDir)\fuze"
$global:FuzDecode = "$($global:WorkingDirFuzDecode)\BmlFuzDecode.exe"


#
# Function : Convert-ToFuz
# Convert fuz file to xmp with BmlFuzDecode
#
Function Convert-ToFuz {

    Param(
        [string]$FuzFile
    )

    If (Test-Path $global:FuzDecode) {
        If (Test-Path $FuzFile) {
            If ($FuzFile.EndsWith(".fuz")) {
                $sOutputPath = Split-Path $FuzFile -Parent

                $sOutputFile = (Split-Path $FuzFile -Leaf)
                $sOutputFile = $sOutputFile.Substring(0, ($sOutputFile.Length -3)) + "xmp"

                $sOutput = "$($sOutputPath)\$($sOutputFile)"

                If (-not (Test-Path $sOutput)) {
                    $arrArgs = @()
                    $arrArgs += "$([char]34)$($FuzFile)$([char]34)"
                    $arrArgs += "$([char]34)$($sOutput)$([char]34)"

                    Write-Host "Generating $($sOutputFile)..."
                    $p = Start-Process -FilePath $global:FuzDecode -WorkingDirectory $global:WorkingDirFuzDecode -ArgumentList $arrArgs -NoNewWindow -Wait -PassThru
                
                    if ($p.ExitCode -eq 0) {
                        Write-Warning "Fuze Decode : success"
                    } else {
                        Write-Warning "Fuze Decode : failed?"
                    }
                } else {
                    Write-Warning "$($sOutput) already exists."
                }
            } else {
                Write-Warning "$($FuzFile) not a fuze file?"
            }
        }
    } else {
        Write-Warning "BmlFuzDecode missing?!"
    }
}


#
# Function : Convert-FuzBulk 
# Convert fuz files in bulk to xmp
#
Function Convert-FuzBulk  {
    Param (
        [string]$Root
    )

    Write-Host "Bulk converting Skyrim fuze files to xmp."
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
# convert all fuz (Skyrim Fuze files) files in folder 'in-place' to xmp files.
# .fuz files get converted, serial wise a.k.a. synchronious, to .xmp.
# the output xmp file is placed next to the existing fuz file.
#
Convert-FuzBulk -Root ".\extracted_sfx"
