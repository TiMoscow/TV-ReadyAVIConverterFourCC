import subprocess
import json
from pathlib import Path

# -----------------------------
# настройки
# -----------------------------
TARGET_CODECS = {"XVID", "DIVX", "DIV5", "DX50"}  # Какие кодеки меняем
NEW_FOURCC = "FMP4"
VIDEO_EXT = ".avi"
LOG_FILE = Path("fourcc_change_log.txt")
FRAMES_TO_TEST = 10  #  сколько кадров проверять после изменения тегов, для декодирования

# -----------------------------
# функции
# -----------------------------
def run_cmd(cmd):
    """Единая функция запуска команд (фикс кодировки)"""
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore"
    )

def get_video_streams(file_path):
    """Возвращает список видеопотоков с их FourCC"""
    cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "v",
        "-show_entries", "stream=codec_tag_string,index",
        "-of", "json",
        str(file_path)
    ]
    result = run_cmd(cmd)

    if result.returncode != 0:
        raise RuntimeError(f"ffprobe error: {result.stderr}")
    data = json.loads(result.stdout)
    return data.get("streams", [])

def check_video(file_path):
    """Проверка видео - ffprobe"""
    try:
        streams = get_video_streams(file_path)
        if len(streams) == 0:
            return False
    except Exception:
        return False

    # Дополнительно: декодируем несколько первых кадров
    cmd = [
        "ffmpeg", "-v", "error",
        "-i", str(file_path),
        "-frames:v", str(FRAMES_TO_TEST),
        "-f", "null",
        "-"
    ]
    result = run_cmd(cmd)

    return result.returncode == 0

def change_fourcc(file_path):
    streams = get_video_streams(file_path)
    changed = False

    # проверяем видеопотоки
    for stream in streams:
        codec = stream.get("codec_tag_string", "").upper()
        if codec in TARGET_CODECS:
            changed = True

    if not changed:
        return False

    temp_file = file_path.with_suffix(".tmp.avi")
    cmd = [
        "ffmpeg", "-y", "-i", str(file_path),
        "-c", "copy",
        "-vtag", NEW_FOURCC,
        str(temp_file)
    ]
    result = run_cmd(cmd)

    if result.returncode != 0:
        raise RuntimeError(f"FFmpeg error: {result.stderr}")

    # проверка работоспособности файлов
    if check_video(temp_file):
        temp_file.replace(file_path)
        return True
    else:
        temp_file.unlink(missing_ok=True)
        raise RuntimeError("файл не читается или иная ошибка")

# -----------------------------
# обработка
# -----------------------------
def main():
    folder = Path.cwd()
    log_lines = []

    files = list(folder.rglob(f"*{VIDEO_EXT}"))
    total = len(files)

    print(f"Найдено файлов: {total}\n")

    for i, file_path in enumerate(files, 1):
        print(f"[{i}/{total}] Проверка: {file_path}")

        try:
            streams = get_video_streams(file_path)

            target_found = any(
                stream.get("codec_tag_string", "").upper() in TARGET_CODECS
                for stream in streams
            )

            if not target_found:
                print(f"[SKIP] Нет нужного FourCC")
                log_lines.append(f"[SKIP] Нет нужного FourCC: {file_path}")
                continue

            print(f"[PROCESSING] Меняем FourCC...")

            changed = change_fourcc(file_path)

            if changed:
                print(f"[OK] Готово\n")
                log_lines.append(f"[OK] FourCC изменили: {file_path}")
            else:
                print(f"[SKIP] Без изменений\n")
                log_lines.append(f"[SKIP] Без изменений: {file_path}")

        except Exception as e:
            print(f"[ERROR] {e}\n")
            log_lines.append(f"[ERROR] {file_path}: {e}")

    with open(LOG_FILE, "a", encoding="utf-8") as f:
        for line in log_lines:
            f.write(line + "\n")
    print(f"\nЛог: {LOG_FILE}")

# -----------------------------
# запуск
# -----------------------------
if __name__ == "__main__":
    main()
