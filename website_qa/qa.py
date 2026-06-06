from __future__ import annotations

import re
from dataclasses import asdict

from .gemini_client import generate_answer_with_gemini, is_gemini_enabled
from .retrieval import BM25Retriever, LOW_VALUE_SECTIONS, SearchResult
from .text import split_sentences, tokenize


LOW_QUALITY_PHRASES = (
    "Asturianu",
    "Coordinates",
    "Archived from the original",
    "Retrieved",
    "Website egyptianmuseumcairo",
    "تعديل مصدري",
    "سجل الميداليات",
    "عدد مرات الظهور",
    "المواقع الموقع",
    "هذه المقالة جزء من سلسلة",
    "استكشف جميع البرامج",
    "جولات المتحف خرائط المتحف",
    "يحدث الآن متحف الأطفال",
    "كلمات مُقترحة",
    "سياسة ملفات تعريف الارتباط",
)

ARABIC_PATTERN = re.compile(r"[\u0600-\u06ff]")


def _is_quality_sentence(sentence: str) -> bool:
    stripped = sentence.strip()
    if stripped.startswith("^") or stripped.startswith("["):
        return False
    if any(phrase in sentence for phrase in LOW_QUALITY_PHRASES):
        return False
    if len(sentence.split()) > 80 and "." not in sentence:
        return False
    return True


def _sentence_score(sentence: str, query_tokens: set[str], retrieval_score: float, context: str = "") -> float:
    sentence_tokens = tokenize(sentence)
    if not sentence_tokens:
        return 0.0
    sentence_token_set = set(sentence_tokens)
    context_tokens = set(tokenize(context))
    overlap = len(query_tokens.intersection(sentence_token_set))
    context_overlap = len(query_tokens.intersection(context_tokens))
    density = overlap / max(1, len(set(sentence_tokens)))
    score = overlap * 2.0 + context_overlap * 1.5 + density + retrieval_score * 0.15
    lower_sentence = sentence.lower()
    if query_tokens and query_tokens.issubset(sentence_token_set):
        score += 2.0
    if any(pattern in lower_sentence for pattern in (" is a ", " is an ", " is the ", " are a ", " are an ")):
        score += 1.5
    if any(pattern in sentence for pattern in (" هو ", " هي ", " يُعد ", " يعد ", " تعتبر ", " يُعتبر ")):
        score += 1.0
    if any(pattern in sentence for pattern in ("هو لاعب", "هي لاعبة", "هو لاعب كرة", "هي لاعبة كرة")):
        score += 10.0
        if "who" in query_tokens:
            score += 4.0
    if "لاعب" in sentence and any(token in query_tokens for token in ("footballer", "player", "football")):
        score += 2.0
    if "what" in query_tokens and any(
        pattern in sentence for pattern in ("تربط", "يعرض", "تعرض", "يضم", "يحتوي", "يقع", "يسعى", "تصفح مجموعة")
    ):
        score += 2.5
    return score


def _contains_arabic(value: str) -> bool:
    return bool(ARABIC_PATTERN.search(value or ""))


def _arabic_no_answer() -> str:
    return "لم أجد إجابة في محتوى المواقع المفهرسة."


def _detect_answer_language(answer: str, *, query_is_arabic: bool) -> str:
    arabic_chars = len(ARABIC_PATTERN.findall(answer or ""))
    latin_chars = len(re.findall(r"[A-Za-z]", answer or ""))
    if arabic_chars > latin_chars:
        return "ar"
    return "en"


def _dedupe_sentences(sentences: list[tuple[float, str, SearchResult]]) -> list[tuple[float, str, SearchResult]]:
    selected: list[tuple[float, str, SearchResult]] = []
    seen: set[str] = set()
    for item in sentences:
        normalized = " ".join(item[1].lower().split())
        if normalized in seen:
            continue
        seen.add(normalized)
        selected.append(item)
    return selected


def _format_answer(sentences: list[tuple[float, str, SearchResult]], *, mode: str) -> str:
    selected = _dedupe_sentences(sentences)
    if not selected:
        return ""
    if mode == "generative":
        best_chunk_id = selected[0][2].chunk.id
        same_chunk = [item for item in selected if item[2].chunk.id == best_chunk_id]
        remaining = [item for item in selected if item[2].chunk.id != best_chunk_id]
        expanded = [*same_chunk, *remaining]
        return " ".join(_clean_answer_sentence(sentence, result) for _, sentence, result in expanded[: min(3, len(expanded))])
    return _clean_answer_sentence(selected[0][1], selected[0][2])


def _format_evidence(sentences: list[tuple[float, str, SearchResult]], *, limit: int = 6) -> str:
    selected = _dedupe_sentences(sentences)
    lines: list[str] = []
    for _, sentence, result in selected[:limit]:
        clean_sentence = _clean_answer_sentence(sentence, result)
        lines.append(f"- {clean_sentence}")
    return "\n".join(lines)


def _clean_answer_sentence(sentence: str, result: SearchResult) -> str:
    cleaned = re.sub(r"\[\s*(?:\d+|[a-z]+|note\s+\d+)\s*\]", "", sentence)
    arabic_definition_markers = ("هو لاعب", "هي لاعبة", "هو سياسي", "هي سياسية", "هو ممثل", "هي ممثلة")
    for marker in arabic_definition_markers:
        marker_index = cleaned.find(marker)
        if marker_index > 20:
            return re.sub(r"\s+", " ", cleaned[marker_index:]).strip()

    title = result.chunk.title.replace(" - Wikipedia", "").strip()
    title_index = cleaned.lower().find(title.lower()) if title else -1
    if title_index > 40:
        cleaned = cleaned[title_index:]
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned.strip()


def build_answer(
    query: str,
    retriever: BM25Retriever,
    *,
    mode: str = "extractive",
    top_k: int = 4,
) -> dict:
    wants_arabic = _contains_arabic(query)
    results = retriever.search(query, top_k=max(top_k, 12))
    if not results:
        return {
            "answer": _arabic_no_answer() if wants_arabic else "I could not find an answer in the indexed website content.",
            "confidence": 0.0,
            "mode": mode,
            "sources": [],
            "answer_language": "ar" if wants_arabic else "en",
        }

    query_tokens = set(tokenize(query))
    ranked_sentences: list[tuple[float, str, SearchResult]] = []

    for result in results:
        if result.chunk.section.strip().lower() in LOW_VALUE_SECTIONS:
            continue
        context = f"{result.chunk.section} {result.chunk.section} {result.chunk.title}"
        for sentence in split_sentences(result.chunk.text):
            if not _is_quality_sentence(sentence):
                continue
            score = _sentence_score(sentence, query_tokens, result.score, context=context)
            if score > 0:
                ranked_sentences.append((score, sentence, result))

    ranked_sentences.sort(key=lambda item: item[0], reverse=True)
    if not ranked_sentences:
        best = results[0]
        ranked_sentences = [(best.score, best.chunk.text, best)]

    used_gemini = False
    if mode == "generative" and is_gemini_enabled():
        language_hint = "ar" if wants_arabic else "en"
        evidence = _format_evidence(ranked_sentences)
        gemini_answer = generate_answer_with_gemini(
            question=query,
            evidence=evidence,
            language_hint=language_hint,
        )
        if gemini_answer:
            answer = gemini_answer
            used_gemini = True
        else:
            answer = _format_answer(ranked_sentences, mode=mode)
    else:
        answer = _format_answer(ranked_sentences, mode=mode)
    answer_language = _detect_answer_language(answer, query_is_arabic=wants_arabic)

    best_score = ranked_sentences[0][0]
    confidence = min(0.98, round(best_score / (best_score + 6), 3))

    answer_result = ranked_sentences[0][2]
    ordered_results = [answer_result, *[result for result in results if result.chunk.id != answer_result.chunk.id]]
    sources = []
    seen_urls = set()
    for result in ordered_results:
        chunk = result.chunk
        if chunk.url in seen_urls:
            continue
        seen_urls.add(chunk.url)
        sources.append(
            {
                "url": chunk.url,
                "title": chunk.title,
                "section": chunk.section,
                "score": round(result.score, 3),
                "snippet": chunk.text[:400],
            }
        )

    return {
        "answer": answer,
        "confidence": confidence,
        "mode": mode,
        "answer_language": answer_language,
        "generator": "gemini" if used_gemini else "local",
        "sources": sources,
        "debug": {
            "top_chunk": asdict(answer_result.chunk),
            "retrieval_score": round(answer_result.score, 3),
        },
    }
