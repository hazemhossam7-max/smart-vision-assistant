from __future__ import annotations

import re
from dataclasses import dataclass


TOKEN_PATTERN = re.compile(r"[\w\u0600-\u06ff]+", re.UNICODE)
SENTENCE_PATTERN = re.compile(r"(?<=[.!?\u061f\u06d4])\s+|\n+")
LONG_FRAGMENT_PATTERN = re.compile(r"\s+(?=(?:The|An|A|It|This)\s)")
ARABIC_DIACRITICS_PATTERN = re.compile(r"[\u064b-\u065f\u0670]")

STOPWORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "by",
    "for",
    "from",
    "how",
    "in",
    "is",
    "it",
    "of",
    "on",
    "or",
    "that",
    "the",
    "this",
    "to",
    "what",
    "when",
    "where",
    "which",
    "who",
    "why",
    "with",
    "عن",
    "على",
    "في",
    "من",
    "ما",
    "ماذا",
    "متى",
    "اين",
    "أين",
    "كيف",
    "هو",
    "هي",
    "و",
}

TOKEN_ALIASES = {
    "egyptain": ["egyptian"],
    "egypian": ["egyptian"],
    "متحف": ["museum"],
    "المتحف": ["museum"],
    "متاحف": ["museums", "museum"],
    "مصري": ["egyptian"],
    "المصري": ["egyptian"],
    "مصريه": ["egyptian"],
    "المصريه": ["egyptian"],
    "مصر": ["egypt", "egyptian"],
    "القاهرة": ["cairo"],
    "قاهرة": ["cairo"],
    "كايرو": ["cairo"],
    "اثار": ["antiquities", "archaeology"],
    "الاثار": ["antiquities", "archaeology"],
    "آثار": ["antiquities", "archaeology"],
    "الآثار": ["antiquities", "archaeology"],
    "تاريخ": ["history"],
    "تاريخي": ["history", "historical"],
    "وطني": ["national"],
    "الوطني": ["national"],
    "وطنيه": ["national"],
    "الوطنيه": ["national"],
    "يقع": ["located", "occupies"],
    "مكان": ["location", "located"],
    "اين": ["where", "located"],
    "أين": ["where", "located"],
    "متى": ["when"],
    "بني": ["built", "constructed"],
    "انشئ": ["built", "constructed"],
    "أنشئ": ["built", "constructed"],
    "تاسس": ["founded", "constructed"],
    "تأسس": ["founded", "constructed"],
    "يحتوي": ["houses", "contains"],
    "يضم": ["houses", "contains"],
    "مقتنيات": ["collection", "items"],
    "مجموعة": ["collection"],
    "قطعة": ["items"],
    "قطع": ["items"],
    "فئه": ["category"],
    "فئات": ["categories"],
    "موقع": ["website"],
    "الموقع": ["website"],
    "مواقع": ["websites"],
    "المواقع": ["websites"],
    "مشروع": ["project"],
    "المشروع": ["project"],
    "ما": ["what"],
    "ماذا": ["what"],
    "من": ["who"],
    "كريستيانو": ["cristiano"],
    "كرستيانو": ["cristiano"],
    "رونالدو": ["ronaldo"],
    "رونالدو؟": ["ronaldo"],
    "لاعب": ["footballer", "player"],
    "اللاعب": ["footballer", "player"],
    "كره": ["football"],
    "الكره": ["football"],
    "قدم": ["football"],
}


@dataclass(frozen=True)
class TextChunk:
    id: str
    url: str
    title: str
    section: str
    text: str


def clean_text(value: str) -> str:
    value = re.sub(r"\s+", " ", value or "")
    return value.strip()


def normalize_token(value: str) -> str:
    value = ARABIC_DIACRITICS_PATTERN.sub("", value.lower())
    value = value.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    value = value.replace("ى", "ي").replace("ة", "ه")
    return value


def tokenize(value: str) -> list[str]:
    expanded_tokens: list[str] = []
    for match in TOKEN_PATTERN.finditer(value or ""):
        token = normalize_token(match.group(0))
        aliases = TOKEN_ALIASES.get(token, [])
        if len(token) <= 1:
            continue
        if token not in STOPWORDS:
            expanded_tokens.append(token)
        expanded_tokens.extend(aliases)
    return expanded_tokens


def split_sentences(value: str) -> list[str]:
    sentences: list[str] = []
    for part in SENTENCE_PATTERN.split(value or ""):
        part = clean_text(part)
        if len(part) > 260:
            sentences.extend(clean_text(fragment) for fragment in LONG_FRAGMENT_PATTERN.split(part))
        elif part:
            sentences.append(part)
    return [sentence for sentence in sentences if len(sentence) > 20]


def chunk_text(
    text: str,
    *,
    url: str,
    title: str,
    section: str = "",
    id_prefix: str | None = None,
    chunk_words: int = 170,
    overlap_words: int = 35,
) -> list[TextChunk]:
    words = clean_text(text).split()
    if not words:
        return []

    chunks: list[TextChunk] = []
    start = 0
    chunk_number = 1
    step = max(1, chunk_words - overlap_words)

    while start < len(words):
        end = min(len(words), start + chunk_words)
        chunk = " ".join(words[start:end])
        prefix = id_prefix or url
        chunks.append(
            TextChunk(
                id=f"{prefix}#chunk-{chunk_number}",
                url=url,
                title=title,
                section=section,
                text=chunk,
            )
        )
        if end == len(words):
            break
        start += step
        chunk_number += 1

    return chunks
