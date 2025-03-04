@echo off
:: Версия кода: 0.0.1

setlocal

:: Укажем папку для обработанных файлов
set "outputFolder=Samsung_Yes"

:: Создаем папку, если она не существует
if not exist "%outputFolder%" (
    mkdir "%outputFolder%"
)

:: Обрабатываем все AVI-файлы в текущей папке
for %%f in (*.avi) do (
    echo Обработка файла: %%f
    ffmpeg -i "%%f" -c copy -bsf:v mpeg4_unpack_bframes -vtag FMP4 "%outputFolder%\source_%%f"
    echo Файл сохранен в: "%outputFolder%\source_%%f"
)

echo Все файлы обработаны и сохранены в папку: %outputFolder%
pause