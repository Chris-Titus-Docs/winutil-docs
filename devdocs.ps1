#!/usr/bin/env pwsh

# Script to generate documentation files from feature.json and tweaks.json
# It creates a folder structure based on categories in the JSON files

# Parameters
param(
    [string]$featuresPath = "winutil-main/config/feature.json",
    [string]$tweaksPath = "winutil-main/config/tweaks.json",
    [string]$outputPath = (Join-Path -Path $PSScriptRoot -ChildPath "content/dev")
)

function Get-WinUtilContent {
    $zipPath = "winutil.zip"
    $tempPath = "winutil-main"
    Invoke-WebRequest -Uri "https://github.com/ChrisTitusTech/winutil/archive/refs/heads/main.zip" -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $tempPath
    Remove-Item -Path $zipPath -Force
    return $tempPath
}

function EnsureDirectory {
    param([string]$path)
    if (-not (Test-Path -Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "Created directory: $path"
    }
}

# Function to generate index files for categories
function GenerateCategoryIndex {
    param(
        [string]$categoryPath,
        [string]$categoryName,
        [array]$items,
        [string]$type
    )

    $indexFilePath = Join-Path -Path $categoryPath -ChildPath "_index.md"
    $content = "---`ntitle: `"$categoryName`"`n---`n`n"
    $content += "## Contents`n`n"

    foreach ($item in $items) {
        $name = if ($type -eq "feature") { $item.Name } else { $item.Name }
        $itemTitle = if ($type -eq "feature") { $item.Feature.Content } else { $item.Tweak.Content }
        $lowerName = $name.ToLower()
        $content += "- [$itemTitle](./$lowerName/)`n"
    }

    $content | Out-File -FilePath $indexFilePath -Encoding utf8
    Write-Host "Created index file: $indexFilePath"
}

# Function to generate index files for main sections
function GenerateSectionIndex {
    param(
        [string]$sectionPath,
        [string]$sectionTitle,
        [hashtable]$categories
    )

    $indexFilePath = Join-Path -Path $sectionPath -ChildPath "_index.md"
    $content = "---`ntitle: `"$sectionTitle`"`n---`n`n"
    $content += "## Categories`n`n"

    foreach ($category in $categories.Keys | Sort-Object) {
        $formattedCategory = $category -replace "z__", "" # Remove z__ prefix if present
        $content += "### $formattedCategory`n`n"
        
        foreach ($item in $categories[$category]) {
            $name = if ($item.Feature) { $item.Name } else { $item.Name }
            $itemTitle = if ($item.Feature) { $item.Feature.Content } else { $item.Tweak.Content }
            $lowerCategory = $category.ToLower()
            $lowerName = $name.ToLower()
            $relativePath = "./$lowerCategory/$lowerName/"
            $content += "- [$itemTitle]($relativePath)`n"
        }
        $content += "`n"
    }

    $content | Out-File -FilePath $indexFilePath -Encoding utf8
    Write-Host "Created section index file: $indexFilePath"
}

# Function to generate main index file
function GenerateMainIndex {
    param(
        [string]$outputPath,
        [hashtable]$featureCategories,
        [hashtable]$tweakCategories
    )

    $indexFilePath = Join-Path -Path $outputPath -ChildPath "_index.md"
    $content = "---`ntitle: `"WinUtil Documentation`"`n---`n`n"
    
    # Add Features section
    $content += "## Features`n`n"
    foreach ($category in $featureCategories.Keys | Sort-Object) {
        $formattedCategory = $category -replace "z__", "" # Remove z__ prefix if present
        $content += "### $formattedCategory`n`n"
        
        foreach ($item in $featureCategories[$category]) {
            $lowerOutputPath = $outputPath.ToLower()
            $lowerCategory = $category.ToLower()
            $lowerName = $item.Name.ToLower()
            $relativePath = "../$lowerOutputPath/features/$lowerCategory/$lowerName/"
            $content += "- [$($item.Feature.Content)]($relativePath)`n"
        }
        $content += "`n"
    }
    
    # Add Tweaks section
    $content += "## Tweaks`n`n"
    foreach ($category in $tweakCategories.Keys | Sort-Object) {
        $formattedCategory = $category -replace "z__", "" # Remove z__ prefix if present
        $content += "### $formattedCategory`n`n"
        
        foreach ($item in $tweakCategories[$category]) {
            $lowerOutputPath = $outputPath.ToLower()
            $lowerCategory = $category.ToLower()
            $lowerName = $item.Name.ToLower()
            $relativePath = "../$lowerOutputPath/tweaks/$lowerCategory/$lowerName/"
            $content += "- [$($item.Tweak.Content)]($relativePath)`n"
        }
        $content += "`n"
    }

    $content | Out-File -FilePath $indexFilePath -Encoding utf8
    Write-Host "Created main index file: $indexFilePath"
}

# Function to generate markdown content for a feature/tweak
function GenerateMarkdown {
    param(
        [Parameter(Mandatory=$true)]
        [string]$name,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$item,
        
        [Parameter(Mandatory=$true)]
        [string]$type,
        
        [Parameter(Mandatory=$true)]
        [int]$weight
    )

    # Create Hugo front matter
    $markdown = "---`ntitle: `"$($item.Content)`"`nweight: $weight`n---`n`n"
    
    # Add warning for advanced tweaks
    if ($type -eq "tweak" -and $item.category -eq "z__Advanced Tweaks - CAUTION") {
        $markdown += "> [!WARNING]`n"
        $markdown += "> This is an advanced tweak and is not recommended for the general user. Improper use may cause system instability or unexpected behavior.`n`n"
    }
    
    if ($item.Description) {
        $markdown += "$($item.Description)`n`n"
    }
    
    if ($item.feature -and $item.feature.Count -gt 0) {
        $markdown += "## Features Enabled`n`n"
        foreach ($feature in $item.feature) {
            $markdown += "- $feature`n"
        }
        $markdown += "`n"
    }
    
    if ($item.InvokeScript -and $item.InvokeScript.Count -gt 0) {
        $markdown += "## Scripts Executed`n`n"
        
        # Create code block manually
        $markdown += '```' + "`n"
        
        # Join all scripts with newlines between them
        $scriptContent = ($item.InvokeScript | ForEach-Object { 
            if ($_ -is [string]) {
                # Replace any escaped newlines with actual newlines
                $content = $_.Trim()
                $content = $content -replace '\\r\\n|\\n\\r|\\n|\\r', "`n"
                $content
            } else {
                $_
            }
        }) -join "`n"
        $markdown += "$scriptContent`n"
        
        # Close code block
        $markdown += '```' + "`n`n"
    }
    
    if ($item.registry -and $item.registry.Count -gt 0) {
        $markdown += "## Registry Changes`n`n"
        
        # Create markdown table for registry entries
        $markdown += "| Path | Name | Value | Type |`n"
        $markdown += "|------|------|-------|------|`n"
        
        foreach ($reg in $item.registry) {
            if ($reg -is [string]) {
                # Try to parse the string into components
                $markdown += "| $reg | | | |`n"
            } else {
                # Extract properties from the PSCustomObject
                $path = if ($reg.Path) { $reg.Path } else { "" }
                $name = if ($reg.Name) { $reg.Name } else { "" }
                $value = if ($reg.Value -ne $null) { $reg.Value } else { "" }
                $type = if ($reg.Type) { $reg.Type } else { "" }
                
                # Add row to table
                $markdown += "| $path | $name | $value | $type |`n"
            }
        }
        
        $markdown += "`n"
    }
    
    # Add collapsible section with the full JSON entry
    $markdown += "## JSON Definition`n`n"
    
    # Use the Hugo shortcode for details without backtick escaping
    $markdown += "{{% details title=`"Show JSON Source`" closed=`"true`" %}}`n"
    $markdown += '```json' + "`n"
    
    # Convert the item to JSON
    $jsonContent = $item | ConvertTo-Json -Depth 10
    
    # Replace escaped newlines with actual newlines
    $jsonContent = $jsonContent -replace '\\r\\n|\\n\\r|\\n|\\r', "`n"
    
    $markdown += "$jsonContent`n"
    
    # Close code block and details
    $markdown += '```' + "`n"
    $markdown += '{{% /details %}}' + "`n"
    
    return $markdown
}

Remove-Item -Path "content/dev" -Recurse -Force -ErrorAction SilentlyContinue
Set-Location -Path (Get-WinUtilContent)

# Main execution starts here
Write-Host "Generating documentation..."

# Ensure the main output directory exists
EnsureDirectory -path $outputPath

# Create features and tweaks directories
$featuresOutputPath = Join-Path -Path $outputPath -ChildPath "features"
$tweaksOutputPath = Join-Path -Path $outputPath -ChildPath "tweaks"
EnsureDirectory -path $featuresOutputPath
EnsureDirectory -path $tweaksOutputPath

# Initialize categories
$featureCategories = @{}
$tweakCategories = @{}

# Process feature.json
if (Test-Path -Path $featuresPath) {
    Write-Host "Processing $featuresPath..."
    $featuresContent = Get-Content -Path $featuresPath -Raw | ConvertFrom-Json
    
    # Group features by category
    foreach ($property in $featuresContent.PSObject.Properties) {
        $featureName = $property.Name
        $feature = $property.Value
        
        if ($feature.category) {
            if (-not $featureCategories.ContainsKey($feature.category)) {
                $featureCategories[$feature.category] = @()
            }
            $featureCategories[$feature.category] += @{Name = $featureName; Feature = $feature}
        }
    }
    
    # Create category directories and markdown files
    foreach ($category in $featureCategories.Keys) {
        $categoryPath = Join-Path -Path $featuresOutputPath -ChildPath $category
        EnsureDirectory -path $categoryPath
        
        # Sort items alphabetically by name and assign weights
        $sortedItems = $featureCategories[$category] | Sort-Object { $_.Name }
        $weight = 1
        
        foreach ($item in $sortedItems) {
            $mdFilePath = Join-Path -Path $categoryPath -ChildPath "$($item.Name).md"
            $markdown = GenerateMarkdown -name $item.Name -item $item.Feature -type "feature" -weight $weight
            $markdown | Out-File -FilePath $mdFilePath -Encoding utf8
            Write-Host "Created $mdFilePath"
            $weight++
        }
        
        # Generate index file for this category
        GenerateCategoryIndex -categoryPath $categoryPath -categoryName $category -items $featureCategories[$category] -type "feature"
    }
    
    # Generate index file for features section
    GenerateSectionIndex -sectionPath $featuresOutputPath -sectionTitle "Features" -categories $featureCategories
    
} else {
    Write-Warning "Features file not found: $featuresPath"
}

# Process tweaks.json
if (Test-Path -Path $tweaksPath) {
    Write-Host "Processing $tweaksPath..."
    $tweaksContent = Get-Content -Path $tweaksPath -Raw | ConvertFrom-Json
    
    # Group tweaks by category
    foreach ($property in $tweaksContent.PSObject.Properties) {
        $tweakName = $property.Name
        $tweak = $property.Value
        
        if ($tweak.category) {
            if (-not $tweakCategories.ContainsKey($tweak.category)) {
                $tweakCategories[$tweak.category] = @()
            }
            $tweakCategories[$tweak.category] += @{Name = $tweakName; Tweak = $tweak}
        }
    }
    
    # Create category directories and markdown files
    foreach ($category in $tweakCategories.Keys) {
        $categoryPath = Join-Path -Path $tweaksOutputPath -ChildPath $category
        EnsureDirectory -path $categoryPath
        
        # Sort items alphabetically by name and assign weights
        $sortedItems = $tweakCategories[$category] | Sort-Object { $_.Name }
        $weight = 1
        
        foreach ($item in $sortedItems) {
            $mdFilePath = Join-Path -Path $categoryPath -ChildPath "$($item.Name).md"
            $markdown = GenerateMarkdown -name $item.Name -item $item.Tweak -type "tweak" -weight $weight
            $markdown | Out-File -FilePath $mdFilePath -Encoding utf8
            Write-Host "Created $mdFilePath"
            $weight++
        }
        
        # Generate index file for this category
        GenerateCategoryIndex -categoryPath $categoryPath -categoryName $category -items $tweakCategories[$category] -type "tweak"
    }
    
    # Generate index file for tweaks section
    GenerateSectionIndex -sectionPath $tweaksOutputPath -sectionTitle "Tweaks" -categories $tweakCategories
    
} else {
    Write-Warning "Tweaks file not found: $tweaksPath"
}

# Generate main index file
GenerateMainIndex -outputPath $outputPath -featureCategories $featureCategories -tweakCategories $tweakCategories

# Go back and clean up
Set-Location -Path $PSScriptRoot
Remove-Item -Path "winutil-main" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Documentation generation complete. Files saved to $outputPath"
