@echo off
:: Версия кода: 0.2.3

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
        echo [Пропуск] Файл не содержит XVID/DIVX: !currentFile! >> "%logFile%"
    ) else (
        :: Создание временного файла
        set "tempFile=!currentFile!_temp.avi"
        ffmpeg -i "!currentFile!" -c copy -vtag %newFourCC% -y "!tempFile!" 2>&1 >> "%logFile%"

        :: Проверка успешности FFmpeg
        if errorlevel 1 (
            echo [Ошибка] FFmpeg не смог обработать файл: !currentFile! >> "%logFile%"
            del "!tempFile!" 2>nul
        ) else (
            :: Проверка размера файла (минимум 1 КБ)
            for %%I in ("!tempFile!") do set "tempSize=%%~zI"
            if !tempSize! LSS 1024 (
                echo [Ошибка] Временный файл слишком мал: !currentFile! >> "%logFile%"
                del "!tempFile!" 2>nul
            ) else (
                :: Удаление оригинала и переименование
                del "!currentFile!" 2>nul && (
                    ren "!tempFile!" "%%~nxf"
                    echo del "%%~f" >> "%rollbackFile%"
                    echo ren "%%~f" "%%~nxft" >> "%rollbackFile%"
                ) || (
                    echo [Ошибка] Не удалось удалить оригинал: !currentFile! >> "%logFile%"
                )
            )
        )
    )
    set "currentFile="
)

echo Все файлы обработаны. Лог: %logFile%
echo Для отката запустите: %rollbackFile%
pause