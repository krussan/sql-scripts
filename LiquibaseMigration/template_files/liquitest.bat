@echo off
setlocal enabledelayedexpansion
SET SERVER=
SET USERNAME=
SET PASS=

SET LIQUIBASE_PROFILE=%USERPROFILE%\liquitest.txt

if "%1"=="/h" GOTO help
if "%1"=="/?" GOTO help

IF EXIST "!LIQUIBASE_PROFILE!" GOTO readprofile

GOTO prompt

:readprofile
echo Reading profile ...
for /f "usebackq tokens=1-4 delims=," %%a in ("!LIQUIBASE_PROFILE!") do (
  SET SERVER=%%a
  SET USERNAME=%%b
  SET PASS=%%c
)

rem -- check if we should prompt for profile
IF "%1"=="/r" GOTO prompt
GOTO exec

:prompt
set /p SERVER=Enter servername (!SERVER!):
set /p USERNAME=Enter username (!USERNAME!):
set /p PASS=Enter password (!PASS!):

rem -- Save settings to home directory
echo.!SERVER!,!USERNAME!,!PASS!>"!LIQUIBASE_PROFILE!"
goto exec
 
:exec
mvn install -Ddatabase.server=!SERVER! -Ddatabase.username=!USERNAME! -Ddatabase.password=!PASS!
GOTO xit


:help
echo.
echo L I Q U I T E S T
echo.
echo Helper batch file for testing database with tsqlt.
echo The server, username and password settings are queried on first run and stored under the users profile
echo.
echo Usage ::
echo      liquitest.bat [/r] [/h]
echo.
echo Switches ::
echo   /r	- Deletes the stored settings and prompts for new
echo   /h   - (or /?) Displays this help
echo.



:xit
