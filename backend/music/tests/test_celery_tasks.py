from unittest.mock import MagicMock, patch

import pytest
from celery.exceptions import Retry
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile

from music.models import Song
from music.tasks import process_song_audio

User = get_user_model()


@pytest.fixture
def user(db):
    return User.objects.create_user(
        username="faraz", email="faraz@example.com", password="StrongPass123"
    )


def _fake_audio_file():
    # Not a real MP3 payload; should trigger invalid_audio path.
    return SimpleUploadedFile(
        "track.mp3", b"fake-audio-bytes", content_type="audio/mpeg"
    )


def test_task_marks_song_failed_for_invalid_audio(user, settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path
    song = Song.objects.create(
        owner=user,
        title="Track",
        artist="Faraz",
        album="Demo",
        audio_file=_fake_audio_file(),
        is_public=True,
    )

    result = process_song_audio(song.id)

    song.refresh_from_db()
    assert song.status == Song.ProcessingStatus.FAILED
    assert result["status"] == "invalid_audio"


@patch("music.tasks.MutagenFile")
def test_task_marks_song_ready_with_valid_metadata(
    mock_mutagen, user, settings, tmp_path
):
    settings.MEDIA_ROOT = tmp_path

    fake_audio = MagicMock()
    fake_audio.info.length = 213.7
    mock_mutagen.return_value = fake_audio

    song = Song.objects.create(
        owner=user,
        title="Good Track",
        artist="Faraz",
        album="Demo",
        audio_file=_fake_audio_file(),
        is_public=True,
    )

    result = process_song_audio(song.id)

    song.refresh_from_db()
    assert song.status == Song.ProcessingStatus.READY
    assert song.duration_seconds == 213
    assert result["status"] == "ready"
    assert result["duration"] == 213


def test_task_handles_missing_song(db):
    result = process_song_audio(999999)
    assert result["status"] == "not_found"


def test_task_handles_song_without_file(user):
    song = Song.objects.create(
        owner=user, title="No File", artist="Faraz", album="Demo", is_public=True
    )
    result = process_song_audio(song.id)
    song.refresh_from_db()
    assert song.status == Song.ProcessingStatus.FAILED
    assert result["status"] == "no_file"


def test_upload_triggers_processing(user):
    """Creating a song via API queues + runs task (eager in tests)."""
    from rest_framework.test import APIClient

    client = APIClient()
    client.force_authenticate(user=user)

    res = client.post(
        "/api/songs/",
        {
            "title": "API Track",
            "artist": "Faraz",
            "album": "Demo",
            "audio_file": _fake_audio_file(),
            "is_public": True,
        },
        format="multipart",
    )
    assert res.status_code == 201
    song = Song.objects.get(title="API Track")
    assert song.status in (
        Song.ProcessingStatus.READY,
        Song.ProcessingStatus.FAILED,
    )


@patch("music.tasks.MutagenFile", side_effect=OSError("boom"))
def test_task_retries_on_unexpected_error(mock_mutagen, user, settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path
    settings.CELERY_TASK_ALWAYS_EAGER = True
    settings.CELERY_TASK_EAGER_PROPAGATES = True

    song = Song.objects.create(
        owner=user,
        title="Boom Track",
        artist="Faraz",
        album="Demo",
        audio_file=_fake_audio_file(),
        is_public=True,
    )

    # self.retry raises Retry (eager) or the original exc propagates
    with pytest.raises((Retry, OSError)):
        process_song_audio(song.id)

    song.refresh_from_db()
    assert song.status == Song.ProcessingStatus.FAILED


@patch("music.tasks.MutagenFile")
def test_task_ready_when_audio_has_no_info(mock_mutagen, user, settings, tmp_path):
    settings.MEDIA_ROOT = tmp_path

    # audio is not None, but audio.info is None -> hits the False branch (34->37)
    fake_audio = MagicMock()
    fake_audio.info = None
    mock_mutagen.return_value = fake_audio

    song = Song.objects.create(
        owner=user,
        title="No Info Track",
        artist="Faraz",
        album="Demo",
        audio_file=_fake_audio_file(),
        is_public=True,
    )

    result = process_song_audio(song.id)
    song.refresh_from_db()

    assert song.status == Song.ProcessingStatus.READY
    assert song.duration_seconds == 0
    assert result["duration"] == 0
