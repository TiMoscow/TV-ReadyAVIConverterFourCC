@echo off
chcp 65001 > nul
cd /d "%~dp0"

:: Проверка наличия Python
where python >nul 2>&1
if errorlevel 1 (
    echo [Ошибка] Python не найден. Установите Python и при установке отметьте галочку "Add python.exe to PATH".
    echo Подробнее см. README.md, раздел "Установка и добавление в PATH".
    pause
    exit /b 1
)

:: Проверка наличия FFmpeg
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo [Ошибка] FFmpeg не найден. Установите FFmpeg и добавьте его в PATH.
    echo Подробнее см. README.md, раздел "Установка и добавление в PATH".
    pause
    exit /b 1
)

python process_videos.py
pause