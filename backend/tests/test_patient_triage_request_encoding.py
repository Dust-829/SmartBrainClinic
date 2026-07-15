from pathlib import Path
import sys


BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.microservices.patient.api.patient import _restore_triage_message_content


def test_restore_triage_message_content_from_unicode_escape():
    restored = _restore_triage_message_content(
        "??????????????",
        "\\u6211\\u6709\\u9ad8\\u8840\\u538b\\u5e94\\u8be5\\u6302\\u4ec0\\u4e48\\u79d1\\u5ba4\\u7684\\u53f7",
    )

    assert restored == "我有高血压应该挂什么科室的号"


def test_restore_triage_message_content_keeps_normal_text():
    restored = _restore_triage_message_content(
        "我有高血压应该挂什么科室的号",
        "\\u6211\\u6709\\u9ad8\\u8840\\u538b\\u5e94\\u8be5\\u6302\\u4ec0\\u4e48\\u79d1\\u5ba4\\u7684\\u53f7",
    )

    assert restored == "我有高血压应该挂什么科室的号"
