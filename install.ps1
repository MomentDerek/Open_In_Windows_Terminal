function waitForKdy {
    param($message)
    Write-Host $message -NoNewline
    $null = [Console]::ReadKey('?')
}

# Require admin
if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Main{
    $windows_terminal_path = Get-Command "C:\Program Files\WindowsApps\Microsoft.WindowsTerminal*\WindowsTerminal.exe" -ea 0 | Select-Object -ExpandProperty Source
    if ($windows_terminal_path -eq $null)
    {
        Write-Host "Can't find WindowsTerminal.exe"
        return
    }

    $profile_lines = @'
#===Open in Windows Terminal start===#
# More info: https://github.com/MomentDerek/Open_In_Windows_Terminal
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
# If it's Windows Terminal session
if(Test-Path -Path $env:TEMP\windows_terminal_current_dir.temp -PathType Leaf) {
    # If not admin
    if(!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process shell:appsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App -Verb RunAs
        # Force exit current Windows Terminal session
        Stop-Process -Id (Get-WmiObject win32_process | ? processid -eq  $PID).parentprocessid -Force
    }
    else {
        if(Test-Path -Path $env:TEMP\windows_terminal_current_dir.temp -PathType Leaf) {
            $destination = Get-Content $env:TEMP\windows_terminal_current_dir.temp -First 1
            if((Get-Item $destination -ea 0) -is [IO.FileInfo]) {
                $destination = Split-Path $destination
            }
            Set-Location -Path $destination
            Remove-Item -Path $env:TEMP\windows_terminal_current_dir.temp -Force
        }
    }
}
if(Test-Path -Path $env:TEMP\windows_terminal_nonadmin_current_dir.temp -PathType Leaf) {
    if(Test-Path -Path $env:TEMP\windows_terminal_nonadmin_current_dir.temp -PathType Leaf) {
        $destination = Get-Content $env:TEMP\windows_terminal_nonadmin_current_dir.temp -First 1
        if((Get-Item $destination -ea 0) -is [IO.FileInfo]) {
            $destination = Split-Path $destination
        }
        Set-Location -Path $destination
        Remove-Item -Path $env:TEMP\windows_terminal_nonadmin_current_dir.temp -Force
    }
}
#===Open in Windows Terminal end===#
'@

    if ((Get-Item $PROFILE -ea 0) -isnot [IO.FileInfo])
    {
        New-Item $PROFILE -Type File -Force
        Add-Content -Path $PROFILE -Value $profile_lines
    }
    else
    {
        # If old corresponding block of code exists
        if ((Get-Content $PROFILE -Raw).IndexOf("#===Open in Windows Terminal start===#") -ge 0)
        {
            $tmp_content = (Get-Content $PROFILE -Raw) -replace '(?sm)^#===Open in Windows Terminal start===#\r?$.*^#===Open in Windows Terminal end===#\r?$', $profile_lines
            $tmp_content | Out-File -Encoding "UTF8" $PROFILE -Force
            echo "reflash the profile"
        }
        # If profile exists but doesn't contain the corresponding code
        else
        {
            # The whole profile could take some time to run. We need to put our code at the beginning of the profile
            # so that it can quickly determine if reopen is necessary and avoid the performance penalty.
            echo "find the profile which is set by User, please check"
            Get-Content $PROFILE
            waitForKdy "press enter to continue"
            PrependTo-File -file $PROFILE -content $profile_lines
        }
    }

    $preScript_lines = @'
#===Open in Windows Terminal PreScript start===#
# More info: https://github.com/MomentDerek/Open_In_Windows_Terminal
param($destination)

if (Test-Path $env:TEMP\windows_terminal_current_dir.temp) { 
    Remove-Item -Path $env:TEMP\windows_terminal_current_dir.temp -Force 
}
if (Test-Path $env:TEMP\windows_terminal_nonadmin_current_dir.temp.temp) {
    Remove-Item -Path $env:TEMP\windows_terminal_nonadmin_current_dir.temp -Force 
}
$destination = $destination -replace """",""
Out-File -FilePath "$env:TEMP\windows_terminal_nonadmin_current_dir.temp" -InputObject $destination;
Start-Process shell:appsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App
#===Open in Windows Terminal PreScript end===#
'@
    $preScript_admin_lines = @'
#===Open in Windows Terminal PreScript By admin start===#
# More info: https://github.com/MomentDerek/Open_In_Windows_Terminal
param($destination)

if (Test-Path $env:TEMP\windows_terminal_current_dir.temp) { 
    Remove-Item -Path $env:TEMP\windows_terminal_current_dir.temp -Force 
}
if (Test-Path $env:TEMP\windows_terminal_nonadmin_current_dir.temp) {
    Remove-Item -Path $env:TEMP\windows_terminal_nonadmin_current_dir.temp -Force 
}
$destination = $destination -replace """",""
Out-File -FilePath "$env:TEMP\windows_terminal_current_dir.temp" -InputObject $destination;
Start-Process shell:appsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App
#===Open in Windows Terminal PreScript By admin end===#
'@
    $preScript_path_admin =  [io.path]::Combine((Split-Path -Parent $PROFILE), "PowerShell_openByAdmin.ps1")
    $preScript_path =  [io.path]::Combine((Split-Path -Parent $PROFILE), "PowerShell_openByNoAdmin.ps1")

    if ((Get-Item $preScript_path -ea 0) -isnot [IO.FileInfo])
    {
        New-Item $preScript_path -Type File -Force
        Add-Content -Path $preScript_path -Value $preScript_lines
    }
    else
    {
        # If old corresponding block of code exists
        if ((Get-Content $preScript_path -Raw).IndexOf("#===Open in Windows Terminal PreScript start===#") -ge 0)
        {
            $tmp_content = (Get-Content $preScript_path -Raw) -replace '(?sm)^#===Open in Windows Terminal PreScript start===#\r?$.*^#===Open in Windows Terminal PreScript end===#\r?$', $preScript_lines
            $tmp_content | Out-File $preScript_path -Force
            echo "reflash the PreScript on the Path:"
            echo $preScript_path
            echo ""
        }
        # If profile exists but doesn't contain the corresponding code
        else
        {
            #error
            waitForKdy "Error: the preScript is exist, press Enter to Delete the preScript, or Ctrl+Z to exit"
            New-Item $preScript_path -Type File -Force
            Add-Content -Path $preScript_path -Value $preScript_lines
        }
    }

    if ((Get-Item $preScript_path_admin -ea 0) -isnot [IO.FileInfo])
    {
        New-Item $preScript_path_admin -Type File -Force
        Add-Content -Path $preScript_path_admin -Value $preScript_admin_lines
    }
    else
    {
        # If old corresponding block of code exists
        if ((Get-Content $preScript_path_admin -Raw).IndexOf("#===Open in Windows Terminal PreScript By admin start===#") -ge 0)
        {
            $tmp_content = (Get-Content $preScript_path_admin -Raw) -replace '(?sm)^#===Open in Windows Terminal PreScript By admin start===#\r?$.*^#===Open in Windows Terminal PreScript By admin end===#\r?$', $preScript_admin_lines
            $tmp_content | Out-File $preScript_path_admin -Force
            echo "reflash the PreScript on the Path:"
            echo $preScript_path_admin
            echo ""
        }
        # If profile exists but doesn't contain the corresponding code
        else
        {
            #error
            waitForKdy "Error: the preScript_byAdmin is exist, press Enter to Delete the preScript, or Ctrl+Z to exit"
            New-Item $preScript_path_admin -Type File -Force
            Add-Content -Path $preScript_path_admin -Value $preScript_admin_lines
        }
    }

    

    $registry = @'
Windows Registry Editor Version 5.00
; Note you must write elevate's full path and escape \ and "
; show in context menu when right click all kinds files
[HKEY_CLASSES_ROOT\*\shell\WindowsTerminalByAdmin]
@="Open Windows Terminal Here By Admin"
"Icon"="windows_terminal_path,0"
[HKEY_CLASSES_ROOT\*\shell\WindowsTerminalByAdmin\command]
@="powershell -WindowStyle hidden -NoProfile -File \"powershell_preScript_admin_path\" \"%V\""
; show in context menu when right click empty area of explorer
[HKEY_CLASSES_ROOT\Directory\Background\shell\WindowsTerminalByAdmin]
@="Open Windows Terminal Here By Admin"
"Icon"="windows_terminal_path,0"
[HKEY_CLASSES_ROOT\Directory\Background\shell\WindowsTerminalByAdmin\command]
@="powershell -WindowStyle hidden -NoProfile -File \"powershell_preScript_admin_path\" \"%V\""
; show in context menu when right click directory
[HKEY_CLASSES_ROOT\Directory\shell\WindowsTerminalByAdmin]
@="Open Windows Terminal Here By Admin"
"Icon"="windows_terminal_path,0"
[HKEY_CLASSES_ROOT\Directory\shell\WindowsTerminalByAdmin\command]
@="powershell -WindowStyle hidden -NoProfile -File \"powershell_preScript_admin_path\" \"%V\""
'@
    
    $registry = $registry -replace "windows_terminal_path", ($windows_terminal_path -replace "\\", "\\")
    $registry = $registry -replace "powershell_preScript_admin_path", ($preScript_path_admin -replace "\\","\\")
    $wt_reg = Join-Path -Path (Split-Path -Path $script:MyInvocation.MyCommand.Path -Parent) -ChildPath "wt_admin.reg"
    $registry | Out-File -FilePath $wt_reg -Force
    echo ""
    echo "The registry of Admin one:"
    Get-Content $wt_reg

    $registry = $registry -replace "\\WindowsTerminalByAdmin\\command", "\WindowsTerminal\command"
    $registry = $registry -replace "\\WindowsTerminalByAdmin]", "\WindowsTerminal]"
    $registry = $registry -replace "PowerShell_openByAdmin.ps1", "PowerShell_openByNoAdmin.ps1"
    $registry = $registry -replace " By Admin", ""

    $wt_reg = Join-Path -Path (Split-Path -Path $script:MyInvocation.MyCommand.Path -Parent) -ChildPath "wt.reg"
    $registry | Out-File -FilePath $wt_reg -Force
    echo ""
    echo "The registry of NoAdmin one:"
    Get-Content $wt_reg
    echo ""
    waitForKdy "all is finish, press key to close"
}

function PrependTo-File {
    [cmdletbinding()]
    param (
        [Parameter(Position = 1, ValueFromPipeline = $true, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Object]$file,
        [Parameter(Position = 0, ValueFromPipeline = $false, Mandatory = $true)]
        [string]$content,
        [Parameter(ValueFromPipeline = $false, Mandatory = $false)]
        [Switch]$NoNewline,
        [Parameter(ValueFromPipeline = $false, Mandatory = $false)]
        [Switch]$UnixNewline
    )

    process {
        if ($file -is [string]) {
            $original_file = $file
            $file = Get-Item -Path $file -ea 0
            if ($file -eq $null) {
                New-Item -Path $original_file -ItemType File -Force -ea 0
            }
        }
        $filepath = $file.FullName;
        $tmp_file = $filepath + ".__tmp__";
        $tmp_stream = [System.io.file]::create($tmp_file);
        $original_stream = [System.IO.File]::Open($filepath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite);
        try {
            $msg = $content.ToCharArray();
            $tmp_stream.Write($msg, 0, $msg.length);
            if ($NoNewline -eq $false) {
                if ($UnixNewline -eq $false) {
                    $tmp = [text.encoding]::ASCII.GetBytes("`r")
                    $tmp_stream.Write($tmp, 0, $tmp.length)
                }
                $tmp = [text.encoding]::ASCII.GetBytes("`n")
                $tmp_stream.Write($tmp, 0, $tmp.length)
            }
            $original_stream.Position = 0;
            $original_stream.CopyTo($tmp_stream);
        }
        finally {
            $tmp_stream.flush();
            $tmp_stream.close();
            $original_stream.close();
            if ($error.count -eq 0) {
                [System.io.File]::Delete($filepath);
                [System.io.file]::Move($tmp_file, $filepath);
            } else {
                $error.clear();
                [System.io.file]::Delete($tmp_file);
            }
        }
    }
}


Main