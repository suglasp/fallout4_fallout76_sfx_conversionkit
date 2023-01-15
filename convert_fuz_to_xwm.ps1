
#
# Pieter De Ridder
# Script to convert fuz (Skyrim or Fallout Fuze data type) to xwm (xWMA sound files) in bulk
# https://github.com/suglasp/pwsh_convert_fuz_to_xwm
# created : 05/01/2021
# updated : 15/01/2021
#
# Usage:
# .\convert_fuz_to_xwm.ps1 [-CustomDir <custom_path_directory>]
#
# Notes:
# The initial version used a 3rd party tool called "BmlFuzDecode.exe".
# The lastest version of this script, can read a fuze file in Powershell and extract the xwm data natively.
# Native processing of data files has some benefits :
# - No need for a 3rd party tool;
# - No need to launch a new process per fuz file;
# - The BmlFuzDecode tool wrote a lip file (lip sync data) and a xwm file (sound file);
#   We only need the xwm file, so less I/O for each fuz file that is processed;
# - Potential to process files in Parallel. It can be handled in full native Powershell code (Future).
#

# Global vars
$global:WorkingDir = "$($PSScriptRoot)"

#
# Function : Convert-ToFuz
# Extract xwm data from a single fuz file
#
Function Convert-ToFuz {

    Param(
        [string]$FuzFileName
    )

    If (Test-Path -Path $FuzFileName) {
        # Output Folder path
        [string]$sOutputPath = Split-Path $FuzFileName -Parent

        # Convert the *.fuz file to *.xwm
        [string]$sOutputXwmFile = (Split-Path $FuzFileName -Leaf)
        $sOutputXwmFile = $sOutputXwmFile.Substring(0, ($sOutputXwmFile.Length -3)) + "xwm"

        # Store the new full path for the xwm
        [string]$sOutputXwm = "$($sOutputPath)\$($sOutputXwmFile)"

        # Extract the xwm data from the fuz data file
        If (-not (Test-Path -Path $sOutputXwm)) {
            # fuz file header
            # 4 bytes = FUZE 
            # 4 bytes = unknown/unused
            # 4 bytes = Lip data size. Can be 0 or larger.
            # lip data (if Lip data size is larger then 0)^
            # xwm data

            # $FUZEHeader properties
            # FuzHeaderSize = 12 (always 12 bytes)
            # FuzMagic = First 4 bytes (the string 'FUZE')
            # IsFuze = If the Magic is correct or not (true or false)
            # FuzLipSize = Size of the lip data size. If lip data size is 0, xwm data directly is behind header
            [PSObject]$FUZEHeader = New-Object PSObject
            Add-Member -InputObject $FUZEHeader -MemberType NoteProperty -Name FuzHeaderSize -Value 12

            $FuzFile = [System.IO.File]::OpenRead($FuzFileName)
            $FuzReader = New-Object System.IO.BinaryReader($FuzFile, [System.Text.Encoding]::ASCII)

            # get Fuze "Magic" header
            Add-Member -InputObject $FUZEHeader -MemberType NoteProperty -Name FuzMagic -Value $([System.Text.Encoding]::ASCII.GetString($FuzReader.ReadBytes(4)))

            If ($FUZEHeader.FuzMagic -eq "FUZE") {
                # add a boolean to mark this is a correct FUZE file type
                Add-Member -InputObject $FUZEHeader -MemberType NoteProperty -Name IsFuze -Value $([Bool]$true)

                # skip 4 offset bytes we don't need in the Fuz header
                [void]$FuzReader.BaseStream.Seek(4, [System.IO.SeekOrigin]::Current)

                # read 4 bytes that contain the lip data size
                Add-Member -InputObject $FUZEHeader -MemberType NoteProperty -Name FuzLipSize -Value $([System.BitConverter]::ToUInt32($FuzReader.ReadBytes(4), 0))
            } Else {
                # add a boolean to mark this is NOT a correct FUZE file type
                Add-Member -InputObject $FUZEHeader -MemberType NoteProperty -Name IsFuze -Value $([Bool]$false)
            }

            #Write-Host "DEBUG : IsFuze $($FUZEHeader.IsFuze)"

            If ($FUZEHeader.IsFuze) {
                Write-Host "Generating $($sOutputXwmFile)..."

                # if the Lip data size is larger then 0, the fuz file contains lip data.
                # we skip this data if needed.
                If ($FUZEHeader.FuzLipSize -gt 0) {
                    [void]$FuzReader.BaseStream.Seek($FUZEHeader.FuzLipSize, [System.IO.SeekOrigin]::Current)
                }
            
                # extract and write the xwm data stream to a file on disk
                [UInt32]$XwmDataLen = ($FuzReader.BaseStream.Length - $FUZEHeader.FuzLipSize - $FUZEHeader.FuzHeaderSize)
                #Write-Host "DEBUG : Stream length $($FuzReader.BaseStream.Length)"
                #Write-Host "DEBUG : Header size $($FUZEHeader.FuzHeaderSize)"
                #Write-Host "DEBUG : Lip size $($FUZEHeader.FuzLipSize)"
                #Write-Host "DEBUG : XwmDataLen $($XwmDataLen)"

                [System.Byte[]]$XwmData = [System.Byte[]]::New($XwmDataLen)
                $XwmData = $FuzReader.ReadBytes($XwmDataLen)

                $XwmFile = [System.IO.File]::OpenWrite($sOutputXwm)

                If ($XwmFile) {
                    $XwmFile.Write($XwmData, 0, $XwmData.Length)
                    $XwmFile.Flush()
                    $XwmFile.Close()
                }

                Write-Warning "Fuze Decode : success, xwm data written."
            } Else {
                Write-Warning "Fuze Decode : failed."
                Write-Warning "$($FuzFileName) not a fuze file format!"
            }

            # close file
            If ($FuzReader) {
                $FuzReader.Close()
                $FuzReader = $null
            }

            If ($FuzFile) {
                $FuzFile.Close()
                $FuzFile = $null
            }

        } Else {
            Write-Warning "$([char]34)$($sOutputXwm)$([char]34) already exists."
        }
    }
}


#
# Function : Convert-FuzBulk 
# Extraction xwm data from fuz data files in bulk
#
Function Convert-FuzBulk  {
    Param (
        [string]$Root
    )

    Write-Host "Bulk converting Bethesda(c) fuz data files to xwm data files."
    Write-Host "Indexing files in $($Root)..."

    If (Test-Path $Root) {
        [System.Collections.ArrayList]$arrFuzFiles = @((Get-ChildItem -Path "$($Root)" -File -Filter "*.fuz" -Recurse).FullName)
        
        If ($arrFuzFiles.Length -gt 0) {
            Write-Host "Starting extraction of files..."
            ForEach($FuzFile in $arrFuzFiles) {
                Convert-ToFuz -FuzFile $FuzFile
            }
        } Else {
            Write-Warning "No fuz files found to extract?"
        }
    } Else {
        Write-Warning "$($Root) path not found?"
    }
}


#
# Function : Main
#
# Convert all fuz (Skyrim or Fallout Fuze files) files in folder 'in-place' to xwm files.
# .fuz files contain lip and xwm data. The xwm data is extracted .xwm files.
# The output xwm files are placed next to the existing fuz files.
#
Function Main {

    Param (
        [string[]]$Arguments
    )

    [string]$MyExtractionFolder = "$($global:WorkingDir)\extracted_sfx"  # default extraction folder

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

    Convert-FuzBulk -Root $MyExtractionFolder

    Exit(0)
}



# --- MAIN ---
Main -Arguments $args
