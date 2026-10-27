@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  CloneRepos.bat
REM  Reads RepoDirectory.csv (same folder as this script) and,
REM  for every repo listed, downloads (git clone) the repo into
REM  its FolderName if that folder does not exist yet.
REM
REM  A folder that already exists is not touched. If its origin
REM  is not the address in the CSV (for example an old
REM  github.com/cpmodel address), it is flagged [CHECK]: see
REM  Part 2 of SetUpGuide.docx.
REM
REM  CSV columns: FolderName,RepoName,Pull,Add-Commit-Push
REM  Afterwards, use SyncAllRepos.bat to pull and push.
REM ============================================================

set "SCRIPT_DIR=%~dp0"
set "CSV_FILE=%SCRIPT_DIR%RepoDirectory.csv"

where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: git is not on PATH. Install Git for Windows first.
    pause
    exit /b 1
)

if not exist "%CSV_FILE%" (
    echo ERROR: Could not find RepoDirectory.csv next to this script.
    echo Expected at: %CSV_FILE%
    pause
    exit /b 1
)

echo ============================================================
echo  Clone repos listed in RepoDirectory.csv
echo ============================================================
echo.

for /f "usebackq skip=1 tokens=1-2 delims=," %%A in ("%CSV_FILE%") do (
    call :CloneRepo "%%A" "%%B"
)

echo.
echo ============================================================
echo  Done. Use SyncAllRepos.bat to pull and push from now on.
echo ============================================================
pause
exit /b 0

:CloneRepo
set "FOLDER=%~1"
set "REPO_URL=%~2"
set "REPO_PATH=%SCRIPT_DIR%%FOLDER%"

echo ------------------------------------------------------------
echo Repo: %FOLDER%  (%REPO_URL%)

if exist "%REPO_PATH%\.git" goto :CheckOrigin

if exist "%REPO_PATH%" (
    echo   [SKIP] Folder exists but is not a git repository: %REPO_PATH%
    echo          Rename or move it, then run this again.
    goto :eof
)

echo   Cloning...
git clone "%REPO_URL%" "%REPO_PATH%"
if errorlevel 1 (
    echo   [ERROR] git clone failed for %FOLDER%.
    echo           Check the address and that your GitHub ID has access to cpmodelai.
    goto :eof
)
echo   [OK] Cloned into %REPO_PATH%
goto :eof

:CheckOrigin
set "ORIGIN="
for /f "delims=" %%U in ('git -C "%REPO_PATH%" remote get-url origin 2^>nul') do set "ORIGIN=%%U"
if /i "!ORIGIN!"=="%REPO_URL%" goto :AlreadyThere
if /i "!ORIGIN!"=="%REPO_URL%.git" goto :AlreadyThere
echo   [CHECK] Folder already exists but points to: !ORIGIN!
echo           RepoDirectory.csv says: %REPO_URL%
echo           Rename the folder (for example %FOLDER%_old) and run this again.
goto :eof

:AlreadyThere
echo   [OK] Already cloned.
goto :eof
