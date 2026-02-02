#!/usr/bin/env pwsh
# Ralph for Kimi Code CLI - Autonomous AI agent loop
# Usage: .\ralph.ps1 [max_iterations]
# 
# Based on the Ralph pattern by Geoffrey Huntley and the Ralph project for Amp/Claude
# Adapted for Kimi Code CLI

param(
    [Parameter(Position = 0)]
    [int]$MaxIterations = 10
)

$ErrorActionPreference = "Stop"

# Set UTF-8 encoding for proper Unicode support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# Script directory and file paths
$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

$PrdFile = Join-Path $ScriptDir "prd.json"
$ProgressFile = Join-Path $ScriptDir "progress.txt"
$ArchiveDir = Join-Path $ScriptDir "archive"
$LastBranchFile = Join-Path $ScriptDir ".last-branch"
$PromptFile = Join-Path $ScriptDir "KIMI.md"

# Check prerequisites
if (-not (Get-Command kimi -ErrorAction SilentlyContinue)) {
    Write-Error "Error: Kimi CLI not found. Please install Kimi Code CLI first."
    Write-Error "Visit: https://github.com/moonshotai/kimi-cli"
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Error: git not found. Please install git."
    exit 1
}

if (-not (Test-Path $PrdFile)) {
    Write-Error "Error: prd.json not found at $PrdFile"
    Write-Error "Please create a prd.json file or use the PRD skill to generate one."
    exit 1
}

# Archive previous run if branch changed
if ((Test-Path $PrdFile) -and (Test-Path $LastBranchFile)) {
    try {
        $CurrentBranch = (Get-Content $PrdFile | ConvertFrom-Json).branchName
        $LastBranch = Get-Content $LastBranchFile
        
        if ($CurrentBranch -and $LastBranch -and ($CurrentBranch -ne $LastBranch)) {
            $Date = Get-Date -Format "yyyy-MM-dd"
            $FolderName = $LastBranch -replace '^ralph/', ''
            $ArchiveFolder = Join-Path $ArchiveDir "$Date-$FolderName"
            
            Write-Host "Archiving previous run: $LastBranch" -ForegroundColor Yellow
            New-Item -ItemType Directory -Force -Path $ArchiveFolder | Out-Null
            
            if (Test-Path $PrdFile) {
                Copy-Item $PrdFile $ArchiveFolder
            }
            if (Test-Path $ProgressFile) {
                Copy-Item $ProgressFile $ArchiveFolder
            }
            Write-Host "   Archived to: $ArchiveFolder" -ForegroundColor Yellow
            
            # Reset progress file for new run
            "# Ralph Progress Log" | Set-Content $ProgressFile
            "Started: $(Get-Date)" | Add-Content $ProgressFile
            "---" | Add-Content $ProgressFile
        }
    }
    catch {
        Write-Warning "Could not check/archive previous run: $_"
    }
}

# Track current branch
try {
    if (Test-Path $PrdFile) {
        $CurrentBranch = (Get-Content $PrdFile | ConvertFrom-Json).branchName
        if ($CurrentBranch) {
            $CurrentBranch | Set-Content $LastBranchFile
        }
    }
}
catch {
    Write-Warning "Could not track current branch: $_"
}

# Initialize progress file if it doesn't exist
if (-not (Test-Path $ProgressFile)) {
    "# Ralph Progress Log" | Set-Content $ProgressFile
    "Started: $(Get-Date)" | Add-Content $ProgressFile
    "---" | Add-Content $ProgressFile
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "  Ralph for Kimi Code CLI - Autonomous AI Agent Loop" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Max iterations: $MaxIterations"
Write-Host "PRD file: $PrdFile"
Write-Host "Progress file: $ProgressFile"
Write-Host ""

# Show current status
Write-Host "Current PRD Status:" -ForegroundColor Green
Get-Content $PrdFile | ConvertFrom-Json | Select-Object -ExpandProperty userStories | 
    Select-Object id, title, passes | Format-Table -AutoSize

$CompletedIterations = 0

for ($i = 1; $i -le $MaxIterations; $i++) {
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host "  Ralph Iteration $i of $MaxIterations" -ForegroundColor Cyan
    Write-Host "===============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Run Kimi with the Ralph prompt
    $Output = ""
    try {
        # Use Kimi's print mode for autonomous operation
        # --print enables non-interactive mode (auto-approves actions like --yolo)
        # --final-message-only keeps output clean
        $Output = Get-Content $PromptFile | kimi --print --final-message-only 2>&1
        
        # Also write output to console
        Write-Host $Output
    }
    catch {
        Write-Warning "Iteration $i encountered an error: $_"
        $Output = $_.Exception.Message
    }
    
    $CompletedIterations++
    
    # Check for completion signal
    if ($Output -like "*<promise>COMPLETE</promise>*") {
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host "  RALPH COMPLETED ALL TASKS!" -ForegroundColor Green
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Completed at iteration $i of $MaxIterations" -ForegroundColor Green
        Write-Host ""
        
        # Show final status
        Write-Host "Final PRD Status:" -ForegroundColor Green
        Get-Content $PrdFile | ConvertFrom-Json | Select-Object -ExpandProperty userStories | 
            Select-Object id, title, passes | Format-Table -AutoSize
        
        exit 0
    }
    
    Write-Host ""
    Write-Host "Iteration $i complete. Checking for more work..." -ForegroundColor Yellow
    
    # Show current status
    Write-Host ""
    Write-Host "Current PRD Status:" -ForegroundColor Green
    Get-Content $PrdFile | ConvertFrom-Json | Select-Object -ExpandProperty userStories | 
        Select-Object id, title, passes | Format-Table -AutoSize
    
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Yellow
Write-Host "  RALPH REACHED MAX ITERATIONS" -ForegroundColor Yellow
Write-Host "===============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Ralph reached max iterations ($MaxIterations) without completing all tasks." -ForegroundColor Yellow
Write-Host "Check $ProgressFile for status." -ForegroundColor Yellow
Write-Host ""

# Show final status
Write-Host "Final PRD Status:" -ForegroundColor Green
Get-Content $PrdFile | ConvertFrom-Json | Select-Object -ExpandProperty userStories | 
    Select-Object id, title, passes | Format-Table -AutoSize

exit 1
