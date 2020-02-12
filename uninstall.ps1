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


    if ((Get-Item $PROFILE -ea 0) -isnot [IO.FileInfo])
    {
        "the profile is lost or has deleted, skip delete"
    }
    else
    {
        # If old corresponding block of code exists
        if ((Get-Content $PROFILE -Raw).IndexOf("#===Open in Windows Terminal start===#") -ge 0)
        {
            $tmp_content = (Get-Content $PROFILE -Raw) -replace '(?sm)^#===Open in Windows Terminal start===#\r?$.*^#===Open in Windows Terminal end===#\r?$', ""
            $tmp_content | Out-File $PROFILE -Force
            echo "reflash the profile, please check(show nothing mean the profile is empty):"
            Get-Content $PROFILE
            echo ""
            echo ""
        }
        # If profile exists but doesn't contain the corresponding code
        else
        {
            echo "find the profile which is broken, please check:"
            echo ""
            Get-Content $PROFILE
            echo ""
            echo "if you want to delete it, press enter, or backup first, the path:"
            waitForKdy ($PROFILE)
            Remove-Item $PROFILE -Force
        }
    }

    $preScript_path_admin =  [io.path]::Combine((Split-Path -Parent $PROFILE), "PowerShell_openByAdmin.ps1")
    $preScript_path =  [io.path]::Combine((Split-Path -Parent $PROFILE), "PowerShell_openByNoAdmin.ps1")

    if ((Get-Item $preScript_path -ea 0) -isnot [IO.FileInfo])
    {
        echo ""
        echo "the preScript is lost or has deleted, skip delete"
        echo ""
    }
    else
    {
        Remove-Item $preScript_path -Force
        echo ""
        echo "the preScript has deleted"
        echo ""
    }

    if ((Get-Item $preScript_path_admin -ea 0) -isnot [IO.FileInfo])
    {
        echo ""
        echo "the preScript_ByAdmin is lost or has deleted, skip delete"
        echo ""
    }
    else
    {
        Remove-Item $preScript_path_admin
        echo ""
        echo "the preScript_ByAdmin has deleted"
        echo ""
    }

    

    $registry = @'
Windows Registry Editor Version 5.00
[-HKEY_CLASSES_ROOT\*\shell\WindowsTerminalByAdmin]
[-HKEY_CLASSES_ROOT\Directory\Background\shell\WindowsTerminalByAdmin]
[-HKEY_CLASSES_ROOT\Directory\shell\WindowsTerminalByAdmin]
'@
    $uninstall_wt_admin_reg = Join-Path -Path (Split-Path -Path $script:MyInvocation.MyCommand.Path -Parent) -ChildPath "uninstall_wt_admin.reg"
    $registry | Out-File -FilePath $uninstall_wt_admin_reg -Force
    echo ""
    echo "The registry of Admin one:"
    Get-Content $uninstall_wt_admin_reg

    $registry = $registry -replace "\\WindowsTerminalByAdmin]", "\WindowsTerminal]"

    $uninstall_wt_reg = Join-Path -Path (Split-Path -Path $script:MyInvocation.MyCommand.Path -Parent) -ChildPath "uninstall_wt.reg"
    $registry | Out-File -FilePath $uninstall_wt_reg -Force
    echo ""
    echo "The registry of NoAdmin one:"
    Get-Content $uninstall_wt_reg
    echo ""
    waitForKdy "all is finish, run the two reg file will delete the reg which install.ps1 created, press key to close"
}

Main