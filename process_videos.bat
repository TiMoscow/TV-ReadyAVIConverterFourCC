@echo off
:: Версия кода: 0.0.3

@echo off
chcp 65001 > nul

:: Укажите новый FourCC код
set "newFourCC=FMP4"

:: Укажите имя лог-файла
set "logFile=change_log.txt"

:: Укажите имя файла для отката
set "rollbackFile=rollback.bat"

:: Очищаем лог-файл и файл отката, если они существуют
if exist "%logFile%" del "%logFile%"
if exist "%rollbackFile%" del "%rollbackFile%"

:: Рекурсивно обрабатываем все AVI-файлы
for /r %%f in (*.avi) do (
    echo Обработка файла: %%f
    echo Обработка файла: %%f >> "%logFile%"

    :: Создаем временный файл с новым FourCC кодом
    ffmpeg -i "%%f" -c copy -vtag %newFourCC% -y "%%~dpnf_temp.avi"
    if errorlevel 1 (
        echo Ошибка при обработке файла: %%f
        echo Ошибка при обработке файла: %%f >> "%logFile%"
    ) else (
        :: Логируем изменения
        echo Исходный файл: %%f >> "%logFile%"
        echo Временный файл: %%~dpnf_temp.avi >> "%logFile%"
        echo FourCC изменён на: %newFourCC% >> "%logFile%"
        echo. >> "%logFile%"

        :: Добавляем команду для отката
        echo del "%%f" >> "%rollbackFile%"
        echo ren "%%~dpnf_temp.avi" "%%~nxf" >> "%rollbackFile%"

        :: Удаляем исходный файл и переименовываем временный
        del "%%f"
        ren "%%~dpnf_temp.avi" "%%~nxf"
        echo Файл успешно обработан: %%f
    )
)

echo Все файлы обработаны. Лог сохранён в "%logFile%".
echo Для отката изменений запустите файл "%rollbackFile%".
pause