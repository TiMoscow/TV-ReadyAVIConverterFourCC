@echo off
:: Версия кода: 0.2.0

setlocal enabledelayedexpansion
chcp 65001 > nul

:: Настройки
set "newFourCC=FMP4"
set "logFile=change_log.txt"
set "rollbackFile=rollback.bat"

:: Очистка логов
if exist "%logFile%" del "%logFile%"
if exist "%rollbackFile%" del "%rollbackFile%"

:: Обработка всех AVI-файлов
for /r %%f in (*.avi) do (
    set "currentFile=%%~f"
    echo Обработка: !currentFile!

    :: Проверка FourCC кода через FFmpeg
    ffmpeg -hide_banner -i "!currentFile!" 2>&1 | findstr /i "xvid divx" >nul
    if errorlevel 1 (
        echo [Пропуск] Файл не содержит XVID/DIVX >> "%logFile%"
        goto :next_file
    )

    :: Создание временного файла
    set "tempFile=!currentFile!_temp.avi"
    ffmpeg -i "!currentFile!" -c copy -vtag %newFourCC% -y "!tempFile!" 2>&1 >> "%logFile%"

    :: Проверка успешности FFmpeg
    if errorlevel 1 (
        echo [Ошибка] FFmpeg не смог обработать файл >> "%logFile%"
        del "!tempFile!" 2>nul
        goto :next_file
    )

    :: Проверка размера файла (минимум 1 КБ)
    for %%I in ("!tempFile!") do set "tempSize=%%~zI"
    if !tempSize! LSS 1024 (
        echo [Ошибка] Временный файл слишком мал >> "%logFile%"
        del "!tempFile!" 2>nul
        goto :next_file
    )

    :: Удаление оригинала и переименование
    del "!currentFile!"
    ren "!tempFile!" "%%~nxf"

    :: Запись в rollback.bat
    echo del "%%~f" >> "%rollbackFile%"
    echo ren "%%~f" "%%~nxft" >> "%rollbackFile%"

    :next_file
    set "currentFile="
)

echo Все файлы обработаны. Лог: %logFile%
echo Для отката запустите: %rollbackFile%
pause