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

# -----------------------------
# функции
# -----------------------------
def get_video_streams(file_path):
    """Возвращает список видеопотоков с их FourCC"""
    cmd = [
        "ffprobe", "-v", "error",
        "-select_streams", "v",
        "-show_entries", "stream=codec_tag_string,index",
        "-of", "json",
        str(file_path)
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"ffprobe error: {result.stderr}")
    data = json.loads(result.stdout)
    return data.get("streams", [])

def check_video(file_path):
    """Проверка видео - ffprobe"""
    try:
        streams = get_video_streams(file_path)
        return len(streams) > 0  # один видеопоток - гудд
    except Exception:
        return False

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
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"FFmpeg error: {result.stderr}")

    # проверка работоспособности файлов
    if check_video(temp_file):
        temp_file.replace(file_path)
        return True
    else:
        temp_file.unlink(missing_ok=True)
        raise RuntimeError("файл не читается - ffprobe")

# -----------------------------
# обработка
# -----------------------------
def main():
    folder = Path.cwd()
    log_lines = []

    for file_path in folder.rglob(f"*{VIDEO_EXT}"):
        try:
            changed = change_fourcc(file_path)
            if changed:
                log_lines.append(f"[OK] FourCC changed: {file_path}")
                print(f"[OK] FourCC changed: {file_path}")
            else:
                log_lines.append(f"[SKIP] No target FourCC found: {file_path}")
                print(f"[SKIP] No target FourCC: {file_path}")
        except Exception as e:
            log_lines.append(f"[ERROR] {file_path}: {e}")
            print(f"[ERROR] {file_path}: {e}")

    # лог
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        for line in log_lines:
            f.write(line + "\n")
    print(f"\nЛог: {LOG_FILE}")

# -----------------------------
# запуск
# -----------------------------
if __name__ == "__main__":
    main()
