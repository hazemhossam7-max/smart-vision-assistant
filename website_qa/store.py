from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path

from .scraper import PageContent
from .text import TextChunk, chunk_text


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INDEX_PATH = PROJECT_ROOT / "data" / "website_qa_index.json"


class DocumentStore:
    def __init__(self, path: Path | str = DEFAULT_INDEX_PATH) -> None:
        self.path = Path(path)
        self.chunks: list[TextChunk] = []
        self.load()

    def load(self) -> None:
        if not self.path.exists():
            self.chunks = []
            return
        payload = json.loads(self.path.read_text(encoding="utf-8"))
        self.chunks = [TextChunk(**item) for item in payload.get("chunks", [])]

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        payload = {"chunks": [asdict(chunk) for chunk in self.chunks]}
        self.path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    def clear(self) -> None:
        self.chunks = []
        self.save()

    def add_pages(self, pages: list[PageContent]) -> int:
        existing_ids = {chunk.id for chunk in self.chunks}
        new_chunks: list[TextChunk] = []

        for page in pages:
            sections = page.sections or [("", page.text)]
            for section_index, (section, text) in enumerate(sections, start=1):
                id_prefix = f"{page.url}#section-{section_index}"
                for chunk in chunk_text(text, url=page.url, title=page.title, section=section, id_prefix=id_prefix):
                    if chunk.id not in existing_ids:
                        existing_ids.add(chunk.id)
                        new_chunks.append(chunk)

        self.chunks.extend(new_chunks)
        self.save()
        return len(new_chunks)

    def stats(self) -> dict[str, int]:
        return {
            "pages": len({chunk.url for chunk in self.chunks}),
            "chunks": len(self.chunks),
        }
