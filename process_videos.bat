@echo off
:: Версия кода: 0.3.4

setlocal enabledelayedexpansion
chcp 65001 > nul

:: Проверка наличия FFmpeg
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo [Ошибка] FFmpeg не найден. Установите FFmpeg и добавьте его в PATH.
    pause
    exit /b 1
)

:: Настройки
set "newFourCC=FMP4"
set "logFile=change_log.txt"
set "rollbackFile=rollback.bat"

:: Флаг для создания rollback.bat
set "needRollback=0"

:: Добавляем разделитель и информацию о запуске в лог
echo  - >> "%logFile%"
echo ================================================================================== >> "%logFile%"
echo [%date% %time%] Запуск скрипта: %~f0 >> "%logFile%"
echo Рабочая папка: %cd% >> "%logFile%"
echo ========================================= >> "%logFile%"

:: Обработка всех AVI-файлов
for /r %%f in (*.avi) do (
    set "currentFile=%%~f"
    set "backupFile=%%~dpnf.backup.avi"
    echo Обработка: !currentFile!

    :: Создание резервной копии
    copy "!currentFile!" "!backupFile!" >nul 2>&1
    if not exist "!backupFile!" (
        echo [%date% %time%] [Ошибка] Не удалось создать резервную копию: !currentFile! >> "%logFile%"
        set "needRollback=1"
        goto :next_file
    )

    :: Проверка FourCC кода через FFmpeg
    ffmpeg -hide_banner -i "!currentFile!" 2>&1 | findstr /i "xvid divx" >nul
    if errorlevel 1 (
        echo [%date% %time%] [Пропуск] Файл не содержит XVID/DIVX: !currentFile! >> "%logFile%"
        del "!backupFile!" >nul 2>&1
    ) else (
        :: Записываем параметры оригинального файла в лог
        echo [%date% %time%] Параметры оригинального файла: !currentFile! >> "%logFile%"
        ffmpeg -i "!currentFile!" 2>&1 | findstr /i "stream #" >> "%logFile%"
        ffmpeg -i "!currentFile!" 2>&1 | findstr /i "Duration\|bitrate" >> "%logFile%"

        :: Обработка файла
        ffmpeg -i "!currentFile!" -c copy -vtag %newFourCC% -y "!currentFile!_temp.avi" 2>&1 >> "%logFile%"
        if errorlevel 1 (
            echo [%date% %time%] [Ошибка] FFmpeg не смог обработать файл: !currentFile! >> "%logFile%"
            del "!currentFile!_temp.avi" >nul 2>&1
            set "needRollback=1"
        ) else (
            :: Замена исходного файла
            move /y "!currentFile!_temp.avi" "!currentFile!" >nul 2>&1
            if exist "!currentFile!" (
                echo [%date% %time%] [Успех] Обработан: !currentFile! >> "%logFile%"

                :: Записываем параметры обработанного файла в лог
                echo [%date% %time%] Параметры обработанного файла: !currentFile! >> "%logFile%"
                ffmpeg -i "!currentFile!" 2>&1 | findstr /i "stream #" >> "%logFile%"
                ffmpeg -i "!currentFile!" 2>&1 | findstr /i "Duration\|bitrate" >> "%logFile%"

                :: Удаление резервной копии после успешной обработки
                del "!backupFile!" >nul 2>&1
            ) else (
                echo [%date% %time%] [Ошибка] Не удалось заменить файл: !currentFile! >> "%logFile%"
                set "needRollback=1"
            )
        )
    )

    :next_file
    set "currentFile="
    set "backupFile="
)

:: Создание rollback.bat только при наличии ошибок
if !needRollback! EQU 1 (
    echo Для отката запустите: %rollbackFile%
) else (
    if exist "%rollbackFile%" del "%rollbackFile%"
)

:: Добавляем разделитель в лог
echo ========================================= >> "%logFile%"
echo [%date% %time%] Завершение работы скрипта >> "%logFile%"
echo ================================================================================== >> "%logFile%"

echo Все файлы обработаны. Лог: %logFile%
pause