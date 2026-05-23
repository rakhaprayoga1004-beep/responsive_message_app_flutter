@echo off
echo Starting PHP Built-in Server...
echo =================================
cd /d C:\FlyEnv-Data\app\apache-2.4.67\Apache24\htdocs
C:\FlyEnv-Data\app\php-8.5.6\php.exe -S 192.168.18.7:8090
pause