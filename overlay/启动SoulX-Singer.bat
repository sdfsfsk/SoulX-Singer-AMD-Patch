@echo off
chcp 65001 >nul
setlocal EnableExtensions
title SoulX-Singer - AMD ROCm
cd /d "%~dp0"

set "PYTHON=%~dp0runtime-rocm\Scripts\python.exe"
set "PATH=%~dp0ffmpeg\bin;%~dp0runtime-rocm\Scripts;%PATH%"
set "PYTHONIOENCODING=utf-8"
set "PYTHONUTF8=1"
set "PYTHONNOUSERSITE=1"
set "HF_HOME=%~dp0.hf-cache"
set "HF_HUB_DISABLE_XET=1"
set "MIOPEN_LOG_LEVEL=3"
set "NO_PROXY=localhost,127.0.0.1,0.0.0.0,::1"
set "no_proxy=localhost,127.0.0.1,0.0.0.0,::1"

if not exist "%PYTHON%" (
    echo [ERROR] Portable AMD Python was not found: %PYTHON%
    pause
    exit /b 2
)
if not exist "%~dp0pretrained_models\SoulX-Singer\model.pt" (
    echo [ERROR] Official SVS model.pt was not found.
    pause
    exit /b 3
)
if not exist "%~dp0pretrained_models\SoulX-Singer\model-svc.pt" (
    echo [ERROR] Official SVC model-svc.pt was not found.
    pause
    exit /b 3
)
if not exist "%~dp0pretrained_models\SoulX-Singer-Preprocess\rmvpe\rmvpe.pt" (
    echo [ERROR] Official preprocessing models were not found.
    pause
    exit /b 3
)

echo ============================================================
echo   SoulX-Singer - Windows AMD ROCm 7.2.1 / RX 9070 XT
echo ============================================================
if /I "%~1"=="svc" goto :svc
if /I "%~1"=="svs" goto :svs
if /I "%~1"=="quit" exit /b 0
echo   [1] SVC voice conversion WebUI  ^(port 7861, recommended^)
echo   [2] SVS singing synthesis WebUI ^(port 7860^)
echo   [Q] Quit
echo.
choice /C 12Q /N /M "Select mode: "
if errorlevel 3 exit /b 0
if errorlevel 2 goto :svs

:svc
set "APP=webui_svc.py"
set "PORT=7861"
set "MODE=SVC voice conversion"
goto :launch

:svs
set "APP=webui.py"
set "PORT=7860"
set "MODE=SVS singing synthesis"

:launch
echo.
echo [INFO] Checking AMD ROCm and GPU...
"%PYTHON%" -c "import torch; assert torch.cuda.is_available(), 'AMD ROCm GPU is unavailable'; print('[AMD] PyTorch', torch.__version__, '- HIP', torch.version.hip, '- GPU', torch.cuda.get_device_name(0))"
if errorlevel 1 (
    echo [ERROR] AMD ROCm self-check failed. Startup cancelled.
    pause
    exit /b 4
)

echo [INFO] Checking and clearing old SoulX-Singer listener on port %PORT%...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$port=%PORT%; $listeners=@(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue); foreach($listener in $listeners){$pidValue=[int]$listener.OwningProcess; $proc=Get-CimInstance Win32_Process -Filter ('ProcessId='+$pidValue) -ErrorAction SilentlyContinue; if($null -eq $proc){continue}; if((@('python.exe','pythonw.exe') -notcontains $proc.Name) -or ($proc.CommandLine -notlike '*SoulX-Singer*webui*')){Write-Host ('[ERROR] Port '+$port+' is occupied by another process, PID '+$pidValue+' ('+$proc.Name+')'); exit 21}; Write-Host ('[INFO] Stopping old SoulX-Singer process PID '+$pidValue); Stop-Process -Id $pidValue -Force -ErrorAction Stop}; $deadline=(Get-Date).AddSeconds(10); while((Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) -and ((Get-Date) -lt $deadline)){Start-Sleep -Milliseconds 250}; if(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue){exit 22}"
if errorlevel 1 (
    echo [ERROR] Port %PORT% could not be released safely. Startup cancelled.
    pause
    exit /b 5
)
if defined SOULX_CHECK_ONLY (
    echo [OK] SoulX-Singer AMD environment and model preflight passed.
    exit /b 0
)

echo [INFO] Starting %MODE%: http://127.0.0.1:%PORT%
echo [INFO] Initial model loading can take a while. Keep this window open.
if not defined SOULX_NO_BROWSER start "" /b powershell.exe -NoLogo -NoProfile -WindowStyle Hidden -Command "$deadline=(Get-Date).AddMinutes(10); while((Get-Date) -lt $deadline){if(Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue){Start-Process 'http://127.0.0.1:%PORT%'; break}; Start-Sleep -Seconds 1}"
"%PYTHON%" "%~dp0%APP%" --port %PORT% --fp16

set "EXIT_CODE=%ERRORLEVEL%"
echo.
echo [INFO] SoulX-Singer exited with code: %EXIT_CODE%
pause
exit /b %EXIT_CODE%
