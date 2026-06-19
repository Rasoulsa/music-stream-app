import logging

from celery import shared_task
from mutagen import File as MutagenFile
from mutagen.mp3 import HeaderNotFoundError

from music.models import Song

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=10)
def process_song_audio(self, song_id: int) -> dict:
    try:
        song = Song.objects.get(pk=song_id)
    except Song.DoesNotExist:
        logger.warning("process_song_audio: Song %s not found", song_id)
        return {"song_id": song_id, "status": "not_found"}

    song.status = Song.ProcessingStatus.PROCESSING
    song.save(update_fields=["status"])

    try:
        if not song.audio_file:
            song.status = Song.ProcessingStatus.FAILED
            song.save(update_fields=["status"])
            return {"song_id": song_id, "status": "no_file"}

        song.audio_file.open("rb")
        audio = MutagenFile(song.audio_file)
        song.audio_file.close()

        duration = 0
        if audio is not None and getattr(audio, "info", None) is not None:
            duration = int(getattr(audio.info, "length", 0))

        song.duration_seconds = duration
        song.status = Song.ProcessingStatus.READY
        song.save(update_fields=["duration_seconds", "status"])
        return {"song_id": song_id, "status": "ready", "duration": duration}

    except HeaderNotFoundError:
        # Invalid/corrupt mp3 => business failure, DO NOT retry
        logger.warning("Invalid audio format for song %s", song_id)
        song.status = Song.ProcessingStatus.FAILED
        song.save(update_fields=["status"])
        return {"song_id": song_id, "status": "invalid_audio"}

    except Exception as exc:
        # Transient infra error => retry
        logger.exception("Unexpected error processing song %s", song_id)
        song.status = Song.ProcessingStatus.FAILED
        song.save(update_fields=["status"])
        raise self.retry(exc=exc) from exc
