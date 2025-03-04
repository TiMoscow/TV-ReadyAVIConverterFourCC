@echo off
:: Версия кода: 0.2.6

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
    set "backupFile=%%~dpnf.backup.avi"
    echo Обработка: !currentFile!

    :: Создание резервной копии через копирование (вместо переименования)
    copy "!currentFile!" "!backupFile!" >nul 2>&1
    if not exist "!backupFile!" (
        echo [%date% %time%] [Ошибка] Не удалось создать резервную копию: !currentFile! >> "%logFile%"
        goto :next_file
    )

    :: Проверка FourCC кода через FFmpeg
    ffmpeg -hide_banner -i "!currentFile!" 2>&1 | findstr /i "xvid divx" >nul
    if errorlevel 1 (
        echo [%date% %time%] [Пропуск] Файл не содержит XVID/DIVX: !currentFile! >> "%logFile%"
        del "!backupFile!" >nul 2>&1
    ) else (
        :: Обработка файла
        ffmpeg -i "!currentFile!" -c copy -vtag %newFourCC% -y "!currentFile!_temp.avi" 2>&1 >> "%logFile%"
        if errorlevel 1 (
            echo [%date% %time%] [Ошибка] FFmpeg не смог обработать файл: !currentFile! >> "%logFile%"
            del "!currentFile!_temp.avi" >nul 2>&1
        ) else (
            :: Замена исходного файла
            move /y "!currentFile!_temp.avi" "!currentFile!" >nul 2>&1
            if exist "!currentFile!" (
                echo [%date% %time%] [Успех] Обработан: !currentFile! >> "%logFile%"
                :: Запись в rollback.bat
                echo if exist "!backupFile!" move /y "!backupFile!" "!currentFile!" >> "%rollbackFile%"
            ) else (
                echo [%date% %time%] [Ошибка] Не удалось заменить файл: !currentFile! >> "%logFile%"
            )
        )
        :: Удаление резервной копии после успешной обработки
        del "!backupFile!" >nul 2>&1
    )

    :next_file
    set "currentFile="
    set "backupFile="
)

echo Все файлы обработаны. Лог: %logFile%
echo Для отката запустите: %rollbackFile%
pause