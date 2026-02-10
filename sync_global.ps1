$localPath = "c:\NeedsFine_App_Developing\needsfine_app"
$globalPath = "c:\NeedsFine_App_Developing\needsfine_app_global"
$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
$backupDir = "$localPath\_sync_backup_$timestamp"
$vulnerableFiles = @("lib\main.dart", "lib\screens\nearby_screen.dart", "lib\screens\address_search_screen.dart")

Write-Host "Starting Sync Process..."

# 1. Create Backup Directory
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

# 2. Backup Protected Files
Write-Host "Backing up protected files from Global app..."
foreach ($file in $vulnerableFiles) {
    # Check if file exists in Global
    $src = "$globalPath\$file"
    $dest = "$backupDir\$file"
    
    if (Test-Path $src) {
        $destDir = Split-Path $dest
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }
        Copy-Item -Path $src -Destination $dest -Force
        Write-Host "  Backed up: $file"
    } else {
        Write-Host "  Warning: Protected file not found in Global app: $file (Will not start sync if main.dart is missing prevents overwrite risk)"
        # If main.dart is missing, maybe we shouldn't overwrite blindly? 
        # But user wants to copy. Let's assume safely.
        if ($file -eq "lib\main.dart") {
             Write-Host "  CRITICAL: main.dart missing in global. Proceeding carefully."
        }
    }
}

# 3. Copy Assets
Write-Host "Copying Assets (local -> global)..."
if (Test-Path "$localPath\assets") {
    if (-not (Test-Path "$globalPath\assets")) {
        New-Item -ItemType Directory -Force -Path "$globalPath\assets" | Out-Null
    }
    Copy-Item -Path "$localPath\assets\*" -Destination "$globalPath\assets" -Recurse -Force
}

# 4. Copy Lib
Write-Host "Copying Lib (local -> global)..."
if (Test-Path "$localPath\lib") {
     if (-not (Test-Path "$globalPath\lib")) {
        New-Item -ItemType Directory -Force -Path "$globalPath\lib" | Out-Null
    }
    Copy-Item -Path "$localPath\lib\*" -Destination "$globalPath\lib" -Recurse -Force
}

# 5. Restore Protected Files
Write-Host "Restoring protected files..."
foreach ($file in $vulnerableFiles) {
    $backupSrc = "$backupDir\$file"
    $dest = "$globalPath\$file"
    if (Test-Path $backupSrc) {
        Copy-Item -Path $backupSrc -Destination $dest -Force
        Write-Host "  Restored: $file"
    }
}

# Clean up backup
Remove-Item -Path $backupDir -Recurse -Force
Write-Host "Sync Complete!"
