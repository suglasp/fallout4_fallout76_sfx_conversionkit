
#
# Pieter De Ridder
# Extract Fallout 76 (Or Fallout 4) BA2 archive files
# https://github.com/suglasp/fallout4_fallout76_sfx_conversionkit
# Created : 15/03/2020
# Updated : 29/09/2023
#
# Note : Because I use Powershell and use objects, but not really use OO .NET style architecture,
# I work In each function with Open en Close file statements. Just to be safe.
# You can call this way, any function and it will handle the archive files In a safe manner.
#
# Usage:
# .\fo76_ba2_archive_extracter_early_test.ps1 [-InstallPath <fallout4_fallout76_installpath>] [-Fallout "Fallout4"|"Fallout76"|"Fallout76PTS"] [-ExtractDir <extract_dir>] [-Help]
#


#Region Load assemblies needed
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# [appdomain]::CurrentDomain.GetAssemblies()  # verify if the libs are loaded
#EndRegion


#Region Global vars
[int32]$Global:BA2HeaderSize = 24
[String]$Global:WorkDir      = "$($PSScriptRoot)"
#EndRegion


#Region Functions
#
# Function : Show-FOHelp
# show Cli help
#
Function Show-FOHelp {
    Write-Host ""
    Write-Host "Usage:"
    Write-Host ".\$(Split-Path -Path $MyInvocation.ScriptName -Leaf) [-InstallPath <fallout4_fallout76_installpath>] [-Fallout $([char](34))Fallout4|Fallout76|Fallout76PTS] [-ExtractDir <extract_dir>] [-Help]"
    Write-Host ""
    Exit(0)
}


#
# Function : Get-BA2FileList
# Get list of BA2 archives from a folder path.
#
Function Get-BA2FileList {
    Param(
        [String]$GameInstallationPath
    )

    # create empty array
    [System.Collections.ArrayList]$BA2FilesList = @()

    # hunt BA2 Archive files from given folder
    If (Test-Path -Path $GameInstallationPath) {
        $BA2FilesList = @((Get-ChildItem -Path $GameInstallationPath -File -Filter "*.ba2").FullName)

        # we got some files?
        If ($BA2FilesList.Length -gt 0) {
            Write-Host "Found total number of $($BA2FilesList.Length.ToString()) BA2 Archives."

            # list files to stdout
            ForEach($BA2File In $BA2FilesList) {
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
# Do a raw file dump of the first 24 bytes of a BA2 file In string format?
# (First 24 bytes = BA2 Header)
#
Function Dump-BA2HeaderRaw {
    Param(
        [String]$BA2Filename
    )

    If (Test-Path -Path $BA2Filename) {
        # dump first 24 bytes (BA2 Header) as a string
        [System.Array]$bytes = [System.IO.File]::ReadAllBytes($BA2Filename)
        [String]$BA2Dump = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $Global:BA2HeaderSize)
        Write-Host "---"
        Write-Host "First $($Global:BA2HeaderSize.ToString()) bytes : $($BA2Dump)"
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
        [String]$BA2Filename
    )

    # init empty var
    $BA2Header = $null

    If (Test-Path -Path $BA2Filename) {
        # Create a custom PWSH object for the BA2 Header
        [PSObject]$BA2Header = New-Object PSObject

        # we keep track In the header object the path of the file
        Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveFilePath -Value $($BA2Filename)
    
        # open the BA2 Archive
        [System.IO.Stream]$BA2File = [System.IO.File]::OpenRead($BA2Filename)
        [System.IO.BinaryReader]$BA2Reader = New-Object System.IO.BinaryReader($BA2File, [System.Text.Encoding]::ASCII)
        #[void]$BA2Reader.BaseStream.Seek(0, [System.IO.SeekOrigin]::Begin)

        # get BA2 archive "Magic" text
        Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveMagic -Value $([System.Text.Encoding]::ASCII.GetString($BA2Reader.ReadBytes(4)))

        If ($BA2Header.ArchiveMagic -eq "BTDX") {   
            # get version
            Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveVersion -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))

            # get type of archive (GNRL or DX10)
            Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveType -Value $([System.Text.Encoding]::ASCII.GetString($BA2Reader.ReadBytes(4)))

            # get nr of files In archive
            Add-Member -InputObject $BA2Header -MemberType NoteProperty -Name ArchiveFileCount -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))

            # get nr of files In archive
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
    [System.Collections.ArrayList]$BA2NameTable = [System.Collections.ArrayList]@()

    If ($BA2Header -ne $null) {
        If (Test-Path -Path $BA2Header.ArchiveFilePath) {
            # open the BA2 Archive
            [System.IO.Stream]$BA2File = [System.IO.File]::OpenRead($BA2Header.ArchiveFilePath)
            [System.IO.BinaryReader]$BA2Reader = New-Object System.IO.BinaryReader($BA2File, [System.Text.Encoding]::ASCII)

            # skip all data to offset of the Name Table (end of file)
            [void]$BA2Reader.BaseStream.Seek($BA2Header.ArchiveNameTableOffset, [System.IO.SeekOrigin]::Begin)

            while($BA2Reader.BaseStream.Position -lt $BA2Reader.BaseStream.Length) { 
                [Int16]$len = [System.BitConverter]::ToInt16($BA2Reader.ReadBytes(2), 0)
                [String]$name = [System.Text.Encoding]::ASCII.GetString($BA2Reader.ReadBytes($len))
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
    [System.Collections.ArrayList]$BA2FileTable = [System.Collections.ArrayList]@()
    
    If ($BA2Header -ne $null) {
        If (Test-Path -Path $BA2Header.ArchiveFilePath) {
            # open the BA2 Archive
            [System.IO.Stream]$BA2File = [System.IO.File]::OpenRead($BA2Header.ArchiveFilePath)
            [System.IO.BinaryReader]$BA2Reader = New-Object System.IO.BinaryReader($BA2File, [System.Text.Encoding]::ASCII)

            # skip BA2 header
            [void]$BA2Reader.BaseStream.Seek([long]$Global:BA2HeaderSize, [System.IO.SeekOrigin]::Begin)

            # archive type?
            Switch($BA2Header.ArchiveType) {
                "GNRL" {
                    Write-Host "Archive Type : BA2 General archive"
                    Write-Host ""
                                      
                    # get BA2 file lump signatures
                    For($i = 0; $i -lt $BA2Header.ArchiveFileCount; $i++) {

                        # Create a custom PWSH object for the current BA2 File lump signature
                        [PSObject]$BA2FileSig = New-Object PSObject
                     
                        # keep track of filename In archive we have -> using entry from NameTable
                        [String]$BA2InternalFileName = [String]::Empty
                        
                        If ($BA2NameTable) {
                            # if Nametable is available, fill it the name
                            $BA2InternalFileName = $BA2NameTable[$i];
                        }

                        # object filename
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileName -Value $($BA2InternalFileName)

                        # read file lump signature details and add to object
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileHash -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileExt -Value $([System.Text.Encoding]::ASCII.GetString($BA2Reader.ReadBytes(4)))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileDirHash -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileFlags -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileOffset -Value $([System.BitConverter]::ToUInt64($BA2Reader.ReadBytes(8), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileLenCompressed -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileLenRaw -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))
                        Add-Member -InputObject $BA2FileSig -MemberType NoteProperty -Name FileAlign -Value $([System.BitConverter]::ToUInt32($BA2Reader.ReadBytes(4), 0))   # 0xBAADF00?

						# add object to list
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
# Function : RawWrite-BA2Lump
# Write a byte array using raw bytes to file
#
Function RawWrite-BA2Lump {
    Param(
        [String]$RAWFilename,
        [System.Byte[]]$BA2DataLump
    )

    # dump lump to a disk file (from memory)
    If ($BA2DataLump.Length -gt 0) {        
        [System.IO.Stream]$FSLumpFileHnd = [System.IO.File]::OpenWrite($RAWFilename)

        If ($FSLumpFileHnd) {
            $FSLumpFileHnd.Write($BA2DataLump, 0, $BA2DataLump.Length)
            $FSLumpFileHnd.Flush()
            $FSLumpFileHnd.Close()
        }

        Write-Host "Extracted the data, and written to file $($RAWFilename) !"
    } Else {
        Write-Warning "Extracted data is empty, not written file $($RAWFilename) !"
    }
}

#
# Function : DecompressWrite-BA2Lump
# Decompress a byte array using zip/deflate and write to file
#
Function DecompressWrite-BA2Lump {
    Param(
        [String]$DecompressedFilename,
        [System.Byte[]]$BA2DataLump,
        [UInt32]$BA2UncompressedLength
    )

    # Init empty var
    [System.Byte[]]$decompressedData = [System.Byte[]]::new($BA2UncompressedLength) 
    #[System.Byte[]]$decompressedData = New-Object System.Byte[] $BA2UncompressedLength

    # Deflate
    If ($BA2UncompressedLength -gt 0) {
        If ($BA2DataLump) {
            # copy data lump byte array to a MemoryStream
            [System.IO.MemoryStream]$compressedFileStream = New-Object System.IO.MemoryStream
            $compressedFileStream.Write($BA2DataLump, 0, $BA2DataLump.Length)
        
            # skip ZLib header of 2 bytes In .NET
            [void]$compressedFileStream.Seek(2, [System.IO.SeekOrigin]::Begin)

            # decompress and store
            #[System.IO.StreamReader]$uncompressedZLibStream = New-Object System.IO.StreamReader(New-Object System.IO.Compression.DeflateStream($compressedFileStream, [System.IO.Compression.CompressionMode]::Decompress))
            [System.IO.Compression.DeflateStream]$uncompressedZLibStream = New-Object System.IO.Compression.DeflateStream($compressedFileStream, [System.IO.Compression.CompressionMode]::Decompress)
            [void]$uncompressedZLibStream.Read($decompressedData, 0, $decompressedData.Length)
            $uncompressedZLibStream.Close()
            $uncompressedZLibStream.Dispose()

            #[System.Text.Encoding]$ascii = [System.Text.Encoding]::ASCII
            #[System.Byte[]]$EncodedDecompressedData = $ascii.GetBytes($decompressedData)
            #$EncodedDecompressedData = [Convert]::ToBase64String($decompressedData)

            # write to file
            [System.IO.Stream]$FSLumpFileHnd = [System.IO.File]::OpenWrite($DecompressedFilename)

            if ($FSLumpFileHnd) {
                $FSLumpFileHnd.Write($decompressedData, 1, $decompressedData.Length -1)
                $FSLumpFileHnd.Flush()
                $FSLumpFileHnd.Close()
            
                Write-Host "Decompressed the data, and written to file $($DecompressedFilename) !"
            } Else {
                Write-Warning "Decompressed data is empty, not written file $($DecompressedFilename) !"
            }
        } Else {
            Write-Warning "BA2 Lump is empty!"
        }
    } else {
        Write-Warning "Uncompressed lump size is zero, skipped!"
    }
}

#
# Function : Extract-BA2Data
# Open archive and extract BA2 archive data lumps as files
#
Function Extract-BA2Data {
    Param(
        [PSObject]$BA2Header,
        [PSObject]$BA2FileTable,
        [String]$ExtractDestinationPath
    )
    
    If (Test-Path -Path $ExtractDestinationPath) {
    
        If ($BA2Header -ne $null) {
            If (Test-Path -Path $BA2Header.ArchiveFilePath) {
                Write-Host ""
                Write-Host "Archive File : $($BA2Header.ArchiveFilePath)"

                If ($BA2FileTable -ne $null) {
                    # open the BA2 Archive
                    [System.IO.Stream]$BA2File = [System.IO.File]::OpenRead($BA2Header.ArchiveFilePath)
                    [System.IO.BinaryReader]$BA2Reader = New-Object System.IO.BinaryReader($BA2File, [System.Text.Encoding]::ASCII)

                    # skip BA2 header
                    #[void]$BA2Reader.BaseStream.Seek([long]$Global:BA2HeaderSize, [System.IO.SeekOrigin]::Begin)

                    [String]$BA2ExtractPath = "$($ExtractDestinationPath)\$(Split-Path -Path $BA2Header.ArchiveFilePath -Leaf)"

                    # create extraction folder if needed
                    If (-Not (Test-Path -Path $BA2ExtractPath)) {
                        New-Item -Path $BA2ExtractPath -ItemType Directory -Force -ErrorAction SilentlyContinue
                    }

                    # archive type?
                    Switch($BA2Header.ArchiveType) {
                        "GNRL" {
                            # extract general archive files (PC)
                            Write-Host "Archive Type : BA2 General archive"
                            Write-Host ""
                    
                            If ($BA2FileTable.Length -gt 0) {                                                                                  
                                ForEach($BA2FileSig In $BA2FileTable) {
                                    [String]$packedFilename = Split-Path -Path $BA2FileSig.FileName -Leaf
                                    #[String]$packedFolder   = Split-Path -Path $BA2FileSig.FileName -Parent

                                    # create subfolders if needed
                                    [string[]]$packedSubFolders = (Split-Path -Path  $BA2FileSig.FileName -Parent).ToString().Split('\')
                                    [String]$packedFolderBuildPath = "$($BA2ExtractPath)"
                                    ForEach($packedFolderName In $packedSubFolders) {
                                        $packedFolderBuildPath += "\$($packedFolderName)"

                                        If (-Not (Test-Path -Path $packedFolderBuildPath)) {
                                            New-Item -Path $packedFolderBuildPath -ItemType Directory -Force -ErrorAction SilentlyContinue
                                        }
                                    }
                                    $packedSubFolders = $null                                

                                    # read data lump raw or compressed and write to a file on disk
                                    Write-Host "Extracting $($packedFilename) ..."
                                    
                                    # got to offset In file for extraction of lump data
                                    [void]$BA2Reader.BaseStream.Seek([long]($BA2FileSig.FileOffset), [System.IO.SeekOrigin]::Begin)

                                    # default, we set raw length
                                    [UInt32]$LumpLen = $BA2FileSig.FileLenRaw

                                    # check if we need compressed
                                    If ($BA2FileSig.FileLenCompressed -gt 0) {
                                        $LumpLen = $BA2FileSig.FileLenCompressed
                                    }

                                    # construct lump filename
                                    $LumpFileName = "$($packedFolderBuildPath)\$($packedFilename)"

                                    # skip lump extraction, if we already extracted the data before
                                    If (-Not (Test-Path -Path $LumpFileName)) {
                                        # create byte array to host data
                                        $LumpData = [System.Byte[]]::New($LumpLen)
                                        $LumpData = $BA2Reader.ReadBytes($LumpLen)
                                        
                                        # decompress data lump if needed
                                        If ($BA2FileSig.FileLenCompressed -gt 0) {
                                            # decompress and write lump data
                                            DecompressWrite-BA2Lump -DecompressedFilename $LumpFileName -BA2DataLump $LumpData -BA2UncompressedLength $BA2FileSig.FileLenRaw
                                            #[System.Byte[]]$LumpDataTemp = Decompress-BA2Lump -BA2DataLump $LumpData -BA2UncompressedLength $BA2FileSig.FileLenRaw
                                            #$LumpDataTemp | Get-Member
                                            #Write-Host "Len : $($LumpDataTemp.Length)"
                                            #$LumpDataTemp.CopyTo($LumpData)                                                                                                                                                               
                                        } Else {
                                            # write raw lump data
                                            RawWrite-BA2Lump  -RAWFilename $LumpFileName -BA2DataLump $LumpData
                                        }

                                    } Else {
                                        Write-Warning "Already extracted the data, skipped!"
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
        [string[]]$Arguments
    )

    [String]$FalloutGame        = "Fallout 76"                      # Change this to Fallout 4, Fallout 76, Fallout 76 Public Test Server
    [String]$FalloutInstallPath = [String]::Empty                   # FO Installation path. Dynamically looked up or overrided by user.
    [String]$MyExtractionFolder = "$($PSScriptRoot)\extracted_sfx"  # The data Extraction folder location.

    # logic for cmdline arguments
    If ($Arguments) {
        for($i = 0; $i -lt $Arguments.Length; $i++) {
            #Write-Host "DEBUG : Arg $($i.ToString()) is $($Arguments[$i])"

            # default, a PWSH Switch statement on a String is always case insensitive
            Switch ($Arguments[$i]) {
                "-InstallPath" {                    
                    # manually override Fallout Installation Path
                    If (($i +1) -le $Arguments.Length) {
                        $FalloutInstallPath = $Arguments[$i +1]
                    }

                    # remove trailing backslash if needed
                    If ($FalloutInstallPath.EndsWith('\')) {
                        $FalloutInstallPath = $FalloutInstallPath.Substring(0, $FalloutInstallPath.Length -1)
                    }    
                }

                "-Fallout" {
                    # manually override Fallout game
                    If (($i +1) -le $Arguments.Length) {
                        $FalloutGame = $Arguments[$i +1]
                    }

                    # convert cmdline game codes to Steam parsable names (Windows registry)
                    Switch ($FalloutGame) {
                        "Fallout4" { $FalloutGame = "Fallout 4" }
                        "Fallout76" { $FalloutGame = "Fallout 76" }
                        "Fallout76PTS" { $FalloutGame = "Fallout 76 Public Test Server" } 
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

                "-Help" {
                    # show Cli help
                    Show-FOHelp
                }
            }                        
        }
    }

    # Hunt down default paths (if empty, otherwise user provided a path and we skip this step)
    If ($FalloutInstallPath.Length -eq 0) {
        # try Valve Steam app registry settings
		#
		# notice:
		#   app id for Fallout 4      =  377160
		#   app id for Fallout 76     = 1151340
		#   app id for Fallout 76 PTS = 1836200
		#   reg key for Steam         = HKLM:\SOFTWARE\WOW6432Node\Valve\Steam\InstallPath
		#   reg key for App ID's      = HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App <id>\InstallLocation
		[bool]$bSteamInstalled = $false
		
		# Query for x86 Windows Steam
		If (Test-Path -Path "HKLM:\SOFTWARE\Valve\Steam") {
			Try {
				[String]$SteamInstallPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Valve\Steam").InstallPath
				
				If (-Not ([String]::IsNullOrEmpty($SteamInstallPath))) {
					$bSteamInstalled = $true
				}
			} Catch {
				# no Steam present?
			}
		}
		
		# Retry for x64 Windows Steam
		If (-Not ($bSteamInstalled)) {
			If (Test-Path -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam") {
				Try {
					[String]$SteamInstallPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam").InstallPath
					
					If (-Not ([String]::IsNullOrEmpty($SteamInstallPath))) {
						$bSteamInstalled = $true
					}
				} Catch {
					# no Steam present?
				}
			}
		}
		
		# Okay Steam is present on the system. Now Query game folder where it should be installed under the Steam platform
		If ($bSteamInstalled) {
			# fetch list of regex "Steam App*"
			[System.Collections.ArrayList]$paths = @(Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App*")
			
			# enum paths and filter Fallout version we need
			$paths | % {
				If ( (Get-ItemProperty -Path "$($_.Name)".Replace("HKEY_LOCAL_MACHINE", "HKLM:") -Name "DisplayName").DisplayName.Equals($FalloutGame) ) {
					$FalloutInstallPath = (Get-ItemProperty -Path "$($_.Name)".Replace("HKEY_LOCAL_MACHINE", "HKLM:") -Name "InstallLocation").InstallLocation
				}
			}
		}
		
		# try Bethesda Launcher installer paths - depricated
        #If (Test-Path -Path "$($env:ProgramFiles)\Bethesda.net Launcher\games\$($FalloutGame)") {
        #    # x64 OS
        #    $FalloutInstallPath = "$($env:ProgramFiles)\Bethesda.net Launcher\games\$($FalloutGame)\Data"
        #} Else {
        #    # x86 OS
        #    If (Test-Path -Path "$(${env:ProgramFiles(x86)})\Bethesda.net Launcher\games\$($FalloutGame)") {
        #        $FalloutInstallPath = "$(${env:ProgramFiles(x86)})\Bethesda.net Launcher\games\$($FalloutGame)\Data"
        #    }
        #}
		
		# try fixed Valve Steam installer paths - depricated
        #If (Test-Path -Path "$($env:ProgramFiles)\Steam\steamapps\common\$($FalloutGame)") {
        #    # x64 OS
        #    $FalloutInstallPath = "$($env:ProgramFiles)\Steam\steamapps\common\$($FalloutGame)\Data"
        #} Else {
        #    # x86 OS
        #    If (Test-Path -Path "$(${env:ProgramFiles(x86)})\Steam\steamapps\common\$($FalloutGame)") {
        #        $FalloutInstallPath = "$(${env:ProgramFiles(x86)})\Steam\steamapps\common\$($FalloutGame)\Data"
        #    }
        #}
    }


    # Hunt down custom paths (overrided by user)
    If ($FalloutInstallPath.Length -gt 0) {
        # verify custom path with Data folder
        If (Test-Path -Path "$($FalloutInstallPath)\Data") {
            # Append '<game>\Data' sub-folder if needed
            $FalloutInstallPath = $FalloutInstallPath + "\Data"
        }
    }


    Write-Host ""
    Write-Host " --- EXTRACT FALLOUT FILES ---"
    Write-Host " Fallout game : $($FalloutGame)"
    Write-Host " Fallout path : $($FalloutInstallPath)"
    Write-Host ""

    # Get List of BA2 files from the installation path
    [System.Collections.ArrayList]$BA2Files = Get-BA2FileList -GameInstallationPath $FalloutInstallPath

    # Extract each BA2 file
    ForEach($BA2File In $BA2Files) {
        # Read BA2 Archive Header
        [PSObject]$BA2FileHeader = Read-BA2Header -BA2Filename $BA2File

        # Read BA2 Archive Name Table (Note : not all DX10 Archives seem to contain a NameTable)
        [System.Collections.ArrayList]$BA2NameTable = @(Read-BA2NameTable -BA2Header $BA2FileHeader)
		
        # Read BA2 Archive File signatures
        [System.Array]$BA2FileTable = @(Read-BA2FileTable -BA2Header $BA2FileHeader -BA2NameTable $BA2NameTable)
		#[System.Collections.ArrayList]$BA2FileTable = Read-BA2FileTable -BA2Header $BA2FileHeader -BA2NameTable $BA2NameTable
		
        # Create extract BA2 File archive name folder
        If (-Not (Test-Path -Path $MyExtractionFolder)) {
            New-Item -Path $MyExtractionFolder -ItemType Directory -ErrorAction SilentlyContinue
        }

		# Extract the BA2 File archive
		If ($BA2FileTable -Is [System.Array]) {
			Extract-BA2Data -BA2Header $BA2FileHeader -BA2FileTable $BA2FileTable -ExtractDestinationPath $MyExtractionFolder
		}
    }
	
	# Gracefully exit
	Exit(0)
}


# --- MAIN ---
Main -Arguments $args
