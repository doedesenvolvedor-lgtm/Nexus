import os
import subprocess
from pathlib import Path

OUTPUT_RESOLUTIONS = [
    ("1920x1080", "5000k", "1080p"),
    ("1280x720", "2800k", "720p"),
    ("854x480", "1200k", "480p"),
]


def transcode_to_hls(input_video: str, output_folder: str):
    output_path = Path(output_folder)
    output_path.mkdir(parents=True, exist_ok=True)

    playlists = []

    for resolution, bitrate, folder in OUTPUT_RESOLUTIONS:
        target_dir = output_path / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        playlist = target_dir / "playlist.m3u8"

        command = [
            "ffmpeg",
            "-i",
            input_video,
            "-vf",
            f"scale={resolution}",
            "-c:v",
            "libx264",
            "-b:v",
            bitrate,
            "-c:a",
            "aac",
            "-hls_time",
            "6",
            "-hls_playlist_type",
            "vod",
            "-hls_segment_filename",
            str(target_dir / "segment_%03d.ts"),
            str(playlist),
        ]

        subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        playlists.append((folder, bitrate, str(playlist)))

    return playlists


def create_master_playlist(output_folder: str, playlists):
    output_path = Path(output_folder)
    master = output_path / "master.m3u8"

    with master.open("w", encoding="utf-8") as file:
        file.write("#EXTM3U\n")
        for folder, bitrate, _ in playlists:
            file.write(f'#EXT-X-STREAM-INF:BANDWIDTH={bitrate.replace("k", "000")}\n')
            file.write(f"{folder}/playlist.m3u8\n")

    return str(master)


def process_video(input_video: str, output_folder: str):
    playlists = transcode_to_hls(input_video, output_folder)
    master = create_master_playlist(output_folder, playlists)
    return master
