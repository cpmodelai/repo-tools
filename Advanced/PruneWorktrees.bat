@echo off
setlocal EnableDelayedExpansion

rem ============================================================
rem  prune-worktrees.bat
rem  Removes ALL extra git worktrees (even with uncommitted
rem  changes) from each repo, keeping the main checkout.
rem
rem  Repos are found like this:
rem   - If RepoDirectory.csv sits next to this file, it uses the
rem     FolderName column (folders inside BASE).
rem   - Otherwise it checks every subfolder of BASE.
rem
rem  BASE = the folder this .bat lives in. Change it if needed.
rem ============================================================

set "BASE=%~dp0"
set "CSV=%~dp0RepoDirectory.csv"

echo WARNING: uncommitted work in extra worktrees will be lost.
choice /m "Continue"
if errorlevel 2 exit /b

if exist "%CSV%" (
    for /f "usebackq skip=1 tokens=1 delims=," %%F in ("%CSV%") do call :clean "%BASE%%%F"
) else (
    for /d %%D in ("%BASE%*") do call :clean "%%~fD"
)

echo.
echo Done.
pause
exit /b

:clean
set "REPO=%~1"
if not exist "%REPO%\.git" (
    echo -- Skipping %REPO% ^(not a repo^)
    exit /b
)
echo.
echo == %REPO%

rem Fix links in case folders were moved or renamed
git -C "%REPO%" worktree repair >nul 2>&1

rem Drop entries whose folders are already gone
git -C "%REPO%" worktree prune -v

rem Remove every worktree except the first one (the main checkout)
set "FIRST=1"
for /f "tokens=1,* delims= " %%A in ('git -C "%REPO%" worktree list --porcelain') do (
    if "%%A"=="worktree" (
        if "!FIRST!"=="1" (
            set "FIRST=0"
        ) else (
            echo    removing %%B
            git -C "%REPO%" worktree remove --force --force "%%B"
        )
    )
)

git -C "%REPO%" worktree prune
exit /b
