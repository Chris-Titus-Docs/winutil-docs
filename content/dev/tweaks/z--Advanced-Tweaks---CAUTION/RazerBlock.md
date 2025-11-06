# Razer Block

Last Updated: 2025-11-06


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Block Razer Software Installs

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content": "Block Razer Software Installs",
    "Description": "Blocks ALL Razer Software installations. The hardware works fine without any software. WARNING: this will also block all Windows third-party driver installations.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a032_",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DriverSearching",
        "Name": "SearchOrderConfig",
        "Value": "0",
        "OriginalValue": "1",
        "Type": "DWord"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Device Installer",
        "Name": "DisableCoInstallers",
        "Value": "1",
        "OriginalValue": "0",
        "Type": "DWord"
      }
    ],
    "InvokeScript": [
      "
          $RazerPath = \"C:\\Windows\\Installer\\Razer\"
          Remove-Item $RazerPath -Recurse -Force
          New-Item -Path \"C:\\Windows\\Installer\\\" -Name \"Razer\" -ItemType \"directory\"
          $Acl = Get-Acl $RazerPath
          $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule(\"NT AUTHORITY\\SYSTEM\",\"Write\",\"ContainerInherit,ObjectInherit\",\"None\",\"Deny\")
          $Acl.SetAccessRule($Ar)
          Set-Acl $RazerPath $Acl
      "
    ],
    "UndoScript": [
      "
          $RazerPath = \"C:\\Windows\\Installer\\Razer\"
          Remove-Item $RazerPath -Recurse -Force
          New-Item -Path \"C:\\Windows\\Installer\\\" -Name \"Razer\" -ItemType \"directory\"
      "
    ],
    "link": "https://winutil.christitus.com/dev/tweaks/essential-tweaks/razerblock"
}
```

</details>

## Invoke Script

```powershell

	$RazerPath = "C:\Windows\Installer\Razer"

	# Remove existing folder if it exists
	if (Test-Path $RazerPath) {
	    Remove-Item $RazerPath -Recurse -Force
	}

	# Recreate the folder
	New-Item -Path "C:\Windows\Installer\" -Name "Razer" -ItemType "Directory" | Out-Null

	# Get current ACL
	$Acl = Get-Acl $RazerPath

	# Create a deny rule for SYSTEM write access
	$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule(
	    "NT AUTHORITY\SYSTEM",
	    "Write",
	    "ContainerInherit,ObjectInherit",
	    "None",
	    "Deny"
	)

	# Add and apply rule
	$Acl.AddAccessRule($Ar)
	Set-Acl $RazerPath $Acl


```

## Undo Script

```powershell

	$RazerPath = "C:\Windows\Installer\Razer"

	# Remove blocked folder if it exists
	if (Test-Path $RazerPath) {
	    Remove-Item $RazerPath -Recurse -Force
	}

	# Recreate clean folder
	New-Item -Path "C:\Windows\Installer\" -Name "Razer" -ItemType "Directory" | Out-Null
	

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

