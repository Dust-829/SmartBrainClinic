from datetime import date

import pytest

from app.microservices.patient.services import schedule_maintainer


class FakeSession:
    committed = False

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, traceback):
        return False

    async def commit(self):
        self.committed = True


@pytest.mark.asyncio
async def test_ensure_rolling_schedules_generates_today_through_horizon(monkeypatch):
    fake_session = FakeSession()
    captured = {}

    class TestDate(date):
        @classmethod
        def today(cls):
            return cls(2026, 7, 14)

    async def fake_generate(session, start_date, end_date):
        captured["session"] = session
        captured["start_date"] = start_date
        captured["end_date"] = end_date
        return {
            "start_date": start_date,
            "end_date": end_date,
            "generated_count": 3,
            "skipped_count": 2,
            "success": True,
        }

    monkeypatch.setattr(schedule_maintainer, "date", TestDate)
    monkeypatch.setattr(schedule_maintainer, "session_factory", lambda: fake_session)
    monkeypatch.setattr(schedule_maintainer, "generate_scheduling_actuals", fake_generate)

    result = await schedule_maintainer.ensure_rolling_schedules()

    assert captured == {
        "session": fake_session,
        "start_date": "2026-07-14",
        "end_date": "2026-07-21",
    }
    assert fake_session.committed is True
    assert result["generated_count"] == 3
