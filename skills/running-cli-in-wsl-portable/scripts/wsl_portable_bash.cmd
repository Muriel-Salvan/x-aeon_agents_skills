@echo off
set "args=%*"
rem Remove surrounding double quotes if present
if "%args:~0,1%"==""" if "%args:~-1%"==""" set "args=%args:~1,-1%"
rem Remove surrounding single quotes if present
if "%args:~0,1%"=="'" if "%args:~-1%"=="'" set "args=%args:~1,-1%"
wsl --distribution Ubuntu -- BASH_ENV=~/.local/x-aeon/env.bash "$(ls /mnt/*/Env/Linux/Programs/bash/bash)" -c '%args%'
