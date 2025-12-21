@echo off
:: Версия кода: 0.3.9

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

    :: Проверка, содержит ли файл XVID, DIVX или DX50
    ffmpeg -hide_banner -i "!currentFile!" 2>&1 | findstr /i "xvid divx dx50" >nul
    if errorlevel 1 (
        echo [%date% %time%] [Пропуск] Файл не содержит XVID/DIVX/DX50: !currentFile! >> "%logFile%"
        del "!backupFile!" >nul 2>&1
    ) else (
        :: Получаем параметры оригинального файла
        for /f "tokens=*" %%a in ('ffmpeg -i "!currentFile!" 2^>^&1 ^| findstr /i "Stream #"') do set "originalStreams=!originalStreams!%%a\n"
        for /f "tokens=*" %%a in ('ffmpeg -i "!currentFile!" 2^>^&1 ^| findstr /i "Duration\|bitrate"') do set "originalInfo=!originalInfo!%%a\n"
        for /f "tokens=*" %%a in ('ffprobe -v quiet -show_format "!currentFile!" -of json') do set "originalMetadata=!originalMetadata!%%a\n"

        :: Получаем размер оригинального файла
        for %%a in ("!currentFile!") do set "originalSize=%%~za"

        :: Обработка файла с сохранением всех аудиодорожек
        ffmpeg -i "!currentFile!" -map 0 -c copy -vtag %newFourCC% -y "!currentFile!_temp.avi" 2>&1 >> "%logFile%"
        if errorlevel 1 (
            echo [%date% %time%] [Ошибка] FFmpeg не смог обработать файл: !currentFile! >> "%logFile%"
            del "!currentFile!_temp.avi" >nul 2>&1
            set "needRollback=1"
        ) else (
            :: Замена исходного файла
            move /y "!currentFile!_temp.avi" "!currentFile!" >nul 2>&1
            if exist "!currentFile!" (
                echo [%date% %time%] [Успех] Обработан: !currentFile! >> "%logFile%"

                :: Получаем параметры обработанного файла
                for /f "tokens=*" %%a in ('ffmpeg -i "!currentFile!" 2^>^&1 ^| findstr /i "Stream #"') do set "processedStreams=!processedStreams!%%a\n"
                for /f "tokens=*" %%a in ('ffmpeg -i "!currentFile!" 2^>^&1 ^| findstr /i "Duration\|bitrate"') do set "processedInfo=!processedInfo!%%a\n"
                for /f "tokens=*" %%a in ('ffprobe -v quiet -show_format "!currentFile!" -of json') do set "processedMetadata=!processedMetadata!%%a\n"

                :: Получаем размер обработанного файла
                for %%a in ("!currentFile!") do set "processedSize=%%~za"

                :: Сравнение параметров и запись различий в лог
                echo [%date% %time%] Сравнение параметров файла: !currentFile! >> "%logFile%"
                if not "!originalStreams!"=="!processedStreams!" (
                    echo [Различие] Потоки: >> "%logFile%"
                    echo Оригинал: !originalStreams! >> "%logFile%"
                    echo Обработан: !processedStreams! >> "%logFile%"
                )
                if not "!originalInfo!"=="!processedInfo!" (
                    echo [Различие] Информация: >> "%logFile%"
                    echo Оригинал: !originalInfo! >> "%logFile%"
                    echo Обработан: !processedInfo! >> "%logFile%"
                )
                if not "!originalMetadata!"=="!processedMetadata!" (
                    echo [Различие] Метаданные: >> "%logFile%"
                    echo Оригинал: !originalMetadata! >> "%logFile%"
                    echo Обработан: !processedMetadata! >> "%logFile%"
                )
                if not "!originalSize!"=="!processedSize!" (
                    echo [Различие] Размер файла: >> "%logFile%"
                    echo Оригинал: !originalSize! байт >> "%logFile%"
                    echo Обработан: !processedSize! байт >> "%logFile%"
                )

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
    set "originalStreams="
    set "originalInfo="
    set "originalMetadata="
    set "processedStreams="
    set "processedInfo="
    set "processedMetadata="
    set "originalSize="
    set "processedSize="
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