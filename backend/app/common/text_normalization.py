"""Helpers for repairing common mojibake text issues."""

from __future__ import annotations

from typing import Any


def repair_mojibake_text(value: str) -> str:
    text = str(value or "")
    if not text:
        return text

    candidate = _decode_utf8_latin1_mojibake(text)
    if candidate == text:
        return text

    if _text_quality_score(candidate) <= _text_quality_score(text):
        return text
    return candidate


def normalize_text_value(value: Any) -> Any:
    if isinstance(value, str):
        return repair_mojibake_text(value)
    if isinstance(value, list):
        return [normalize_text_value(item) for item in value]
    if isinstance(value, tuple):
        return tuple(normalize_text_value(item) for item in value)
    if isinstance(value, dict):
        return {key: normalize_text_value(item) for key, item in value.items()}
    return value


def _decode_utf8_latin1_mojibake(value: str) -> str:
    try:
        return value.encode("latin-1").decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return value


def _text_quality_score(value: str) -> int:
    cjk_count = sum(1 for ch in value if _is_cjk(ch))
    suspect_count = sum(1 for ch in value if _is_suspect_mojibake_char(ch))
    replacement_count = value.count("?")
    return cjk_count * 4 - suspect_count * 3 - replacement_count


def _is_cjk(ch: str) -> bool:
    codepoint = ord(ch)
    return (
        0x3400 <= codepoint <= 0x4DBF
        or 0x4E00 <= codepoint <= 0x9FFF
        or 0xF900 <= codepoint <= 0xFAFF
    )


def _is_suspect_mojibake_char(ch: str) -> bool:
    codepoint = ord(ch)
    return 0x0080 <= codepoint <= 0x00FF
