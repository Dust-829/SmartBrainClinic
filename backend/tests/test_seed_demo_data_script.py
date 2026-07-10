from pathlib import Path


def test_seed_demo_data_contains_admin_samples():
    seed_sql = Path("scripts/seed_demo_data.sql").read_text(encoding="utf-8")

    assert "CT一室" in seed_sql
    assert "门诊一诊室" in seed_sql
    assert "INSERT INTO outpatient_bill" in seed_sql
    assert "INSERT INTO prescription" in seed_sql
