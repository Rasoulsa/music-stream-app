from config.celery import app, debug_task


def test_celery_app_configured():
    assert app.main == "music"


def test_debug_task_runs(capsys):
    # debug_task is bound; call its underlying run via apply()
    debug_task.apply()
    captured = capsys.readouterr()
    assert "Request:" in captured.out
