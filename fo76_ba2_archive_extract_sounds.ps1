
#
# Pieter De Ridder
# Extract Fallout 76 (Or Fallout 4) Sound files from BA2 archive files
# 15/03/2020
#
# Note : Because I use Powershell and use objects, but not really use OO architecture,
# i work in each Function with Open en Close file statements. Just to be safe.
# You can call this way any Function and it will handle the archive files in a safe manner.
#


#Region Load assemblys needed
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# [appdomain]::CurrentDomain.GetAssemblies()  # verify if the libs are loaded
#EndRegion


#Region Global vars
[int32]$global:BA2HeaderSize = 24
#EndRegion


#Region Functions
#
# Function : Get-BA2FileList
# Get list of BA2 archives from a folder path.
#
Function Get-BA2FileList {
    Param(
        [string]$GameInstallationPath
    )

    # create empty array
    $BA2FilesList = @()

    # hunt BA2 Archive files from given folder
    If (Test-Path $GameInstallationPath) {
        $BA2FilesList = @((Get-ChildItem -Path $GameInstallationPath -File -Filter "*.ba2").FullName)

        # we got some files?
        If ($BA2FilesList.Length -gt 0) {
            Write-Host "Found total number of $($BA2FilesList.Length.ToString()) BA2 Archives."

            # list files to stdout
            ForEach($BA2File in $BA2FilesList) {
                Write-Host "$($BA2File)"
            }
        }
    } Else {
        Write-Warning "Folder $($GameInstallationPath) not found?!"
    }

    # return result
    Return $BA2FilesList
}


#
# Function : Dump-BA2HeaderRaw
# Do a raw file dump of the first 24 bytes of a BA2 file in string format?
# (First 24 bytes = BA2 Header)
#
Function Dump-BA2HeaderRaw {
    Param(
        [string]$BA2Filename
    )

    If (Test-Path $BA2Filename) {
        # dump first 24 bytes (BA2 Header) as a string
        $bytes = [System.IO.File]::ReadAllBytes($BA2Filename)
        $BA2Dump = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $global:BA2HeaderSize)
        Write-Host "---"
        Write-Host "First $($global:BA2HeaderSize.ToString()) bytes : $($BA2Dump)"
        Write-Host "---"
    } else {
        Write-Warning "File $($BA2Filename) not found?!"
    }
}

#
# Function : Read-BA2Header
# Open archive and read the header into an object (begin of the file)
#
Function Read-BA2Header {
    Param(
        [string]$BA2Filename
    )

    # init empty var
    $BA2Header = $null

    If (Test-Path $BA2Filename) {
        # Create a custom PWSH object for the BA2 Header
        $BA2Header = New-Object PSObject

        # we keep track in the header object the path of the file
        Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveFilePath -Value $($BA2Filename)
    
        # open the BA2 Archive
        $BA2File = [System.IO.File]::OpenRead($BA2Filename)
        $BA2Reader = New-Object System.IO.BinaryReader($BA2File, [System.Text.Encoding]::ASCII)
        #[void]$BA2Reader.BaseStream.Seek(0, [System.IO.SeekOrigin]::Begin)

        # get BA2 archive "Magic" text
        Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveMagic -Value $([System.Text.Encoding]::ASCII.GetString($BA2Reader.ReadBytes(4)))

        If ($BA2Header.ArchiveMagic -eq "BTDX") {   
            # get version
            Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveVersion -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))

            # get type of archive (GNRL or DX10)
            Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveType -Value $([System.Text.Encoding]::ASCII.GetString($BA2Reader.ReadBytes(4)))

            # get nr of files in archive
            Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveFileCount -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))

            # get nr of files in archive
            Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveNameTableOffset -Value $([System.BitConverter]::ToUInt64($BA2Reader.ReadBytes(8), 0))
        } Else {
            # bail out!
            Write-Host "Archive type : unknown"
            Write-Warning "Aborted!"
        }


        # close file
        If ($BA2Reader) {
            $BA2Reader.Close()
            $BA2Reader = $null
        }

        If ($BA2File) {
            $BA2File.Close()
            $BA2File = $null
        }
    } Else {
        Write-Warning "File $($BA2Filename) not found?!"
    }

    # return
    Return $BA2Header
}

#
# Function : Read-BA2NameTable
# Open archive and read the Name Table (end of the file)
#
Function Read-BA2NameTable {
    Param(
        [PSObject]$BA2Header
    )
    
    # create empty array
    $BA2NameTable = [System.Collections.ArrayList]@()

    If ($BA2Header -ne $null) {
        If (Test-Path $BA2Header.ArchiveFilePath) {
            # open the BA2 Archive
            $BA2File = [System.IO.File]::OpenRead($BA2Header.ArchiveFilePath)
            $BA2Reader = New-Object System.IO.BinaryReader($BA2File, [System.Text.Encoding]::ASCII)

            # skip all data to offset of the Name Table (end of file)
            [void]$BA2Reader.BaseStream.Seek($BA2Header.ArchiveNameTableOffset, [System.IO.SeekOrigin]::Begin)

            while($BA2Reader.BaseStream.Position -lt $BA2Reader.BaseStream.Length) { 
                [int16]$len = [System.BitConverter]::ToInt16($BA2Reader.ReadBytes(2), 0)
                [string]$name = [System.Text.Encoding]::ASCII.GetString($BA2Reader.ReadBytes($len))
                [void]$BA2NameTable.Add($name.Trim('\0'))
            }

            # close file
            If ($BA2Reader) {
                $BA2Reader.Close()
                $BA2Reader = $null
            }

            If ($BA2File) {
                $BA2File.Close()
                $BA2File = $null
            }
        } Else {
           Write-Warning "File $($BA2Header.ArchiveFilePath) not found?!" 
        }
    } Else {
        Write-Warning "BA2 Header is empty!"
    }

    # return
    Return $BA2NameTable
}


#
# Function : Read-BA2FileTable
# Open archive and read file signatures (middle of the file, after the header)
#
Function Read-BA2FileTable {
    Param(
        [PSObject]$BA2Header,
        [System.Collections.ArrayList]$BA2NameTable
    )
    
    # create empty array
    $BA2FileTable = [System.Collections.ArrayList]@()
    
    If ($BA2Header -ne $null) {
        If (Test-Path $BA2Header.ArchiveFilePath) {
            # open the BA2 Archive
            $BA2File = [System.IO.File]::OpenRead($BA2Header.ArchiveFilePath)
            $BA2Reader = New-Object System.IO.BinaryReader($BA2File, [System.Text.Encoding]::ASCII)

            # skip BA2 header
            [void]$BA2Reader.BaseStream.Seek([long]$global:BA2HeaderSize, [System.IO.SeekOrigin]::Begin)

            # archive type?
            Switch($BA2Header.ArchiveType) {
                "GNRL" {
                    Write-Host "Archive Type : BA2 General archive"
                    Write-Host ""
                                      
                    # get BA2 file lump signatures
                    For($i = 0; $i -lt $BA2Header.ArchiveFileCount; $i++) {

                        # Create a custom PWSH object for the current BA2 File lump signature
                        $BA2FileSig = New-Object PSObject
                     
                        # keep track of filename in archive we have -> using entry from NameTable
                        $BA2InternalFileName = [string]::Empty
                        
                        If ($BA2NameTable) {
                            # if Nametable is available, fill it the name
                            $BA2InternalFileName = $BA2NameTable[$i];
                        }

                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileName -Value $($BA2InternalFileName)


                        # read file lump signature details
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileHash -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileExt -Value $([System.Text.Encoding]::ASCII.GetString($BA2Reader.ReadBytes(4)))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileDirHash -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileFlags -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileOffset -Value $([System.BitConverter]::ToUInt64($BA2Reader.ReadBytes(8), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileLenCompressed -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileLenRaw -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileAlign -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))   # 0xBAADF00?

                        [void]$BA2FileTable.Add($BA2FileSig)
                    }

                }
                "DX10" {
                    Write-Host "Archive Type : BA2 DX10 archive"
                    Write-Host ""
                }

                "GNMF" {
                    Write-Host "Archive Type : BA2 GNMF archive"
                    Write-Host ""
                }
            }
            
            # close file
            If ($BA2Reader) {
                $BA2Reader.Close()
                $BA2Reader = $null
            }

            If ($BA2File) {
                $BA2File.Close()
                $BA2File = $null
            }     
        } Else {
           Write-Warning "File $($BA2Header.ArchiveFilePath) not found?!" 
        }
    } Else {
        Write-Warning "BA2 Header is empty!"
    }

    # Return
    Return $BA2FileTable
}



#
# Function : Decompress-BA2Lump
# Decompress a byte array using ZLib
#
Function Decompress-BA2Lump {
    Param(
        [byte[]]$BA2DataLump
    )

    # Init empty var
    $decompressedZLibSteam = $null

    # Deflate
    If ($BA2DataLump) {
        $compressedFileStream = New-Object System.IO.MemoryStream
        $compressedFileStream.Write($BA2DataLump, 0, $BA2DataLump.Length)
        [void]$compressedFileStream.Seek(0,0)

        $decompressedZLibSteam = New-Object System.IO.Compression.DeflateStream($compressedFileStream, [System.IO.Compression.CompressionMode]::Decompress)
    } Else {
        Write-Warning "BA2 Lump is empty!"
    }

    # Return
    Return $decompressedZLibSteam
}

#
# Function : Extract-BA2Data
# Open archive and extract data lumps
#
Function Extract-BA2Data {
    Param(
        [PSObject]$BA2Header,
        [PSObject]$BA2FileTable,
        [string]$ExtractDestinationPath
    )
    
    If (Test-Path $ExtractDestinationPath) {
    
        If ($BA2Header -ne $null) {
            If (Test-Path $BA2Header.ArchiveFilePath) {
                Write-Host ""
                Write-Host "Archive File : $($BA2Header.ArchiveFilePath)"

                If ($BA2FileTable -ne $null) {
                    # open the BA2 Archive
                    $BA2File = [System.IO.File]::OpenRead($BA2Header.ArchiveFilePath)
                    $BA2Reader = New-Object System.IO.BinaryReader($BA2File, [System.Text.Encoding]::ASCII)

                    # skip BA2 header
                    #[void]$BA2Reader.BaseStream.Seek([long]$global:BA2HeaderSize, [System.IO.SeekOrigin]::Begin)

                    $BA2ExtractPath = "$($ExtractDestinationPath)\$(Split-Path -Path $BA2Header.ArchiveFilePath -Leaf)"

                    # create extraction folder if needed
                    If (-Not(Test-Path $BA2ExtractPath)) {
                        New-Item -Path $BA2ExtractPath -ItemType Directory -Force -ErrorAction SilentlyContinue
                    }

                    # archive type?
                    Switch($BA2Header.ArchiveType) {
                        "GNRL" {
                            # extract general archive files (PC)
                            Write-Host "Archive Type : BA2 General archive"
                            Write-Host ""
                    
                            If ($BA2FileTable.Length -gt 0) {                                                        
                                ForEach($BA2FileSig in $BA2FileTable) {
                                    $packedFilename = Split-Path -Path  $BA2FileSig.FileName -Leaf

                                    If ($packedFilename.EndsWith(".xwm")) {
                                        # read data lump raw or compressed and write to a file on disk
                                        Write-Host "Extracting $(Split-Path -Path  $BA2FileSig.FileName -Leaf) ..."

                                        [void]$BA2Reader.BaseStream.Seek([long]($BA2FileSig.FileOffset), [System.IO.SeekOrigin]::Begin)

                                        If ($BA2FileSig.FileLenCompressed -eq 0) {
                                            # extract non-compressed
                                            $datalumpRaw = [System.Byte[]]::new($BA2FileSig.FileLenRaw)
                                            $datalumpRaw = $BA2Reader.ReadBytes($BA2FileSig.FileLenRaw)

                                            If ($datalumpRaw) {
                                                 # dump lump to a disk file (from memory)
                                                $FSLump = [System.IO.File]::OpenWrite(".\$($BA2ExtractPath)\$(Split-Path -Path $BA2FileSig.FileName -Leaf)")
                                                $FSLump.Write($datalumpRaw, 0, $datalumpRaw.Length)
                                                $FSLump.Flush()
                                                $FSLump.Close()
                                            }
                                        } Else {
                                            # extract compressed
                                            $datalumpC = [System.Byte[]]::new($BA2FileSig.FileLenCompressed)
                                            $datalumpC = $BA2Reader.ReadBytes($BA2FileSig.FileLenCompressed)

                                            If ($datalumpC) {
                                                $datalumpRaw = Decompress-BA2Lump -BA2DataLump $datalumpC
                            
                                                If ($datalumpRaw) {
                                                     # dump lump to a disk file (from memory)
                                                    $FSLump = [System.IO.File]::OpenWrite(".\$($BA2ExtractPath)\$(Split-Path -Path $BA2FileSig.FileName -Leaf)")
                                                    $FSLump.Write($datalumpC, 0, $datalumpC.Length)
                                                    $FSLump.Flush()
                                                    $FSLump.Close()
                                                }
                                            }                                        
                                        }

                                    }
                                }
                            } Else {
                                Write-Warning "No data lumps to extract!"
                            }                  
                        }
                        "DX10" {
                            # extract DX10 archive files (Textures PC)
                            Write-Host "Archive Type : BA2 DX10 archive"
                            Write-Host ""
                            Write-Warning "Archive type not supported by tool!"
                        }

                        "GNMF" {
                            # extract GNMF archive files (for PS4)
                            Write-Host "Archive Type : BA2 GNMF archive"
                            Write-Host ""
                            Write-Warning "Archive type not supported by tool!"
                        }
                    }
            
                    # close file
                    If ($BA2Reader) {
                        $BA2Reader.Close()
                        $BA2Reader = $null
                    }

                    If ($BA2File) {
                        $BA2File.Close()
                        $BA2File = $null
                    }


                } Else {
                    Write-Warning "We need the BA2 filetable data!" 
                }
            } Else {
               Write-Warning "File $($BA2Header.ArchiveFilePath) not found?!" 
            }
        } Else {
            Write-Warning "BA2 Header is empty!"
        }
    } Else {
        Write-Warning "Destination $($ExtractDestinationPath) not found?!"
    }
}
#EndRegion


#
# Function : Main
# Main function
#
Function Main {

    Param (
        $Arguments
    )

    [string]$FalloutGame        = "Fallout76"        # change this to Fallout4 or Fallout76
    [string]$FalloutInstallPath = ""                 # internal var for installation path
    [string]$MyExtractionFolder = ".\extracted_sfx" # extraction folder

    # logic for cmdline arguments
    If ($Arguments) {
        for($i = 0; $i -lt $Arguments.Length; $i++) {
            #Write-Host "DEBUG : Arg $($i.ToString()) is $($args[$i])"

            # default, a PWSH Switch statement on a String is always case insenstive
            Switch ($Arguments[$i]) {
                "-InstallPath" {                    
                    # manually override Fallout Installation Path
                    If (($i +1) -le $Arguments.Length) {
                        $FalloutInstallPath = $Arguments[$i +1]
                    }   
                }

                "-Fallout" {
                    # manually override Fallout game
                    If (($i +1) -le $Arguments.Length) {
                        $FalloutGame = $Arguments[$i +1]
                    }

                    # remove trailing backslash if needed
                    If ($FalloutInstallPath.EndsWith('\')) {
                        $FalloutInstallPath = $FalloutInstallPath.Substring(0, $FalloutInstallPath.Length -1)
                    }                 
                }

                "-ExtractDir" {
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

    # Hunt down paths if not set by user
    If ($FalloutInstallPath.Length -eq 0) {
        # try default Bethesda installer paths
        If (Test-Path ${env:ProgramFiles(x86)}) {
            # x64 OS
            $FalloutInstallPath = "$(${env:ProgramFiles(x86)})\Bethesda.net Launcher\games\$($FalloutGame)\Data"
        } else {
            # x86 OS
            $FalloutInstallPath = "$($env:ProgramFiles)\Bethesda.net Launcher\games\$($FalloutGame)\Data"
        }

        # try Steam installer paths
        If (Test-Path ${env:ProgramFiles(x86)}) {
            # x64 OS
            $FalloutInstallPath = "$(${env:ProgramFiles(x86)})\Steam\steamapps\common\$($FalloutGame)\Data"
        } else {
            # x86 OS
            $FalloutInstallPath = "$($env:ProgramFiles)\Steam\steamapps\common\$($FalloutGame)\Data"
        }
    }


    Write-Host ""
    Write-Host " --- EXTRACT FALLOUT SOUNDS FILES ---"
    Write-Host " Fallout game : $($FalloutGame)"
    Write-Host " Fallout path : $($FalloutInstallPath)"
    Write-Host ""

    # Get List of BA2 files from the installation path
    $BA2Files = Get-BA2FileList -GameInstallationPath $FalloutInstallPath

    # dump each BA2 file header
    ForEach($BA2File in $BA2Files) {
        # read BA2 Archive Header
        $BA2FileHeader = Read-BA2Header -BA2Filename $BA2File

        # read BA2 Archive Name Table
        $BA2NameTable = Read-BA2NameTable -BA2Header $BA2FileHeader

        # read BA2 Arcive File signatures
        $BA2FileTable = Read-BA2FileTable -BA2Header $BA2FileHeader -BA2NameTable $BA2NameTable

        # extract the BA2 File archives
        If (-Not(Test-Path $MyExtractionFolder)) {
            New-Item -Path $MyExtractionFolder -ItemType Directory
        }

        Extract-BA2Data -BA2Header $BA2FileHeader -BA2FileTable $BA2FileTable -ExtractDestinationPath $MyExtractionFolder
    }
}


# --- MAIN ---
Main
