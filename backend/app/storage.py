from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict


class RecognitionStorage:
    """Simple JSONL-backed storage for recognition metadata."""

    def __init__(self, base_upload_dir: Path, history_filename: str = "recognitions_log.jsonl"):
        self.base_upload_dir = Path(base_upload_dir)
        self.base_upload_dir.mkdir(parents=True, exist_ok=True)
        self.history_path = self.base_upload_dir / history_filename
        if not self.history_path.exists():
            self.history_path.touch()

    def append_record(self, record: Dict[str, Any]) -> None:
        enriched = {
            **record,
            "logged_at": datetime.utcnow().isoformat(),
        }
        with self.history_path.open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(enriched, ensure_ascii=False) + "\n")

    def latest_records(self, limit: int = 20) -> list[Dict[str, Any]]:
        lines = []
        with self.history_path.open("r", encoding="utf-8") as stream:
            for line in stream:
                line = line.strip()
                if not line:
                    continue
                lines.append(json.loads(line))
        return lines[-limit:]
