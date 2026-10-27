@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  SyncAllRepos.bat
REM  Reads RepoDirectory.csv (same folder as this script) and,
REM  for every repo listed, pulls the latest main, then stages,
REM  commits and pushes all local changes back to main.
REM
REM  CSV columns: FolderName,RepoName,Pull,Add-Commit-Push
REM  Use this at the start of the day (pull) and/or end of the
REM  day (commit+push) - it does both in one pass.
REM ============================================================

set "SCRIPT_DIR=%~dp0"
set "CSV_FILE=%SCRIPT_DIR%RepoDirectory.csv"

if not exist "%CSV_FILE%" (
    echo ERROR: Could not find RepoDirectory.csv next to this script.
    echo Expected at: %CSV_FILE%
    pause
    exit /b 1
)

echo ============================================================
echo  Repo Sync - Pull / Add / Commit / Push
echo ============================================================
echo  You will be prompted for a separate commit message for
echo  each repo that has changes to push.
echo ============================================================
echo.

set "FIRST_LINE=1"

for /f "usebackq skip=1 tokens=1-4 delims=," %%A in ("%CSV_FILE%") do (
    call :ProcessRepo "%%A" "%%B" "%%C" "%%D"
)

echo.
echo ============================================================
echo  All repos processed.
echo ============================================================
pause
exit /b 0

:ProcessRepo
set "FOLDER=%~1"
set "REPO_URL=%~2"
set "PULL_FLAG=%~3"
set "PUSH_FLAG=%~4"

REM Strip any UTF-8 BOM / stray characters from folder name just in case
set "FOLDER=%FOLDER:"=%"

echo ------------------------------------------------------------
echo Repo: %FOLDER%  (%REPO_URL%)

set "REPO_PATH=%SCRIPT_DIR%%FOLDER%"

if not exist "%REPO_PATH%" (
    echo   [SKIP] Folder not found: %REPO_PATH%
    goto :eof
)

if not exist "%REPO_PATH%\.git" (
    echo   [SKIP] Not a git repository: %REPO_PATH%
    goto :eof
)

pushd "%REPO_PATH%"

REM --- Make sure we're on main before pulling/pushing ---
git rev-parse --verify main >nul 2>&1
if !errorlevel! equ 0 (
    git checkout main >nul 2>&1
) else (
    echo   [WARN] No local "main" branch found, staying on current branch.
)

if /i "%PULL_FLAG%"=="Y" (
    echo   Pulling latest changes...
    git pull
    if !errorlevel! neq 0 (
        echo   [ERROR] git pull failed for %FOLDER%. Skipping commit/push for this repo.
        popd
        goto :eof
    )
)

if /i "%PUSH_FLAG%"=="Y" (
    echo   Staging all changes...
    git add -A

    git diff --cached --quiet
    if !errorlevel! equ 0 (
        echo   No changes to commit.
    ) else (
        set "COMMIT_MSG="
        set /p COMMIT_MSG="  Enter commit message for %FOLDER%: "
        if "!COMMIT_MSG!"=="" (
            echo   [SKIP] No commit message entered. Skipping commit/push for %FOLDER%.
            popd
            goto :eof
        )

        echo   Committing...
        git commit -m "!COMMIT_MSG!"
        if !errorlevel! neq 0 (
            echo   [ERROR] git commit failed for %FOLDER%.
            popd
            goto :eof
        )

        echo   Pushing to main...
        git push origin HEAD:main
        if !errorlevel! neq 0 (
            echo   [ERROR] git push failed for %FOLDER%.
            popd
            goto :eof
        )
    )
)

popd
goto :eof
