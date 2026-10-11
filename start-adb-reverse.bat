@echo off
title KSPPS PASTI - ADB Reverse Port 8000
set ADB="C:\Users\Irpanai\AppData\Local\Android\Sdk\platform-tools\adb.exe"

set IP=192.168.100.114:39577
echo Default IP Device: %IP%
set /p USER_IP="Masukkan IP:Port Wireless HP (tekan ENTER untuk memakai %IP%): "
if not "%USER_IP%"=="" set IP=%USER_IP%

echo.
echo Menghubungkan ke %IP%...
%ADB% connect %IP%

echo Mengaktifkan Port Forwarding (HP localhost:8000 -^> Laptop localhost:8000)...
%ADB% reverse tcp:8000 tcp:8000

echo.
echo Daftar reverse port aktif:
%ADB% reverse --list

echo.
echo ================================================================
echo BERHASIL! Port 8000 di HP telah tersambung ke laptop.
echo Biarkan jendela terminal ini tetap terbuka selama testing.
echo ================================================================
pause
