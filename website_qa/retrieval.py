from __future__ import annotations

import math
from collections import Counter, defaultdict
from dataclasses import dataclass

from .text import TextChunk, tokenize


LOW_VALUE_SECTIONS = {
    "references",
    "external links",
    "see also",
    "notes",
    "bibliography",
    "citations",
    "further reading",
    "notes and references",
    "وصلات خارجية",
    "مراجع",
    "انظر أيضا",
    "انظر أيضًا",
    "مصادر",
}


@dataclass(frozen=True)
class SearchResult:
    chunk: TextChunk
    score: float


class BM25Retriever:
    def __init__(self, chunks: list[TextChunk], *, k1: float = 1.5, b: float = 0.75) -> None:
        self.chunks = chunks
        self.k1 = k1
        self.b = b
        self.doc_tokens = [
            tokenize(f"{chunk.title} {chunk.section} {chunk.section} {chunk.text}") for chunk in chunks
        ]
        self.doc_lengths = [len(tokens) for tokens in self.doc_tokens]
        self.avg_doc_length = sum(self.doc_lengths) / len(self.doc_lengths) if self.doc_lengths else 0
        self.term_frequencies = [Counter(tokens) for tokens in self.doc_tokens]
        self.document_frequencies: dict[str, int] = defaultdict(int)

        for tokens in self.doc_tokens:
            for token in set(tokens):
                self.document_frequencies[token] += 1

    def search(self, query: str, *, top_k: int = 5) -> list[SearchResult]:
        query_tokens = tokenize(query)
        if not query_tokens or not self.chunks:
            return []

        scores: list[SearchResult] = []
        doc_count = len(self.chunks)

        for index, chunk in enumerate(self.chunks):
            score = 0.0
            doc_length = self.doc_lengths[index] or 1
            frequencies = self.term_frequencies[index]

            for token in query_tokens:
                if token not in frequencies:
                    continue
                df = self.document_frequencies.get(token, 0)
                idf = math.log(1 + (doc_count - df + 0.5) / (df + 0.5))
                tf = frequencies[token]
                denominator = tf + self.k1 * (1 - self.b + self.b * doc_length / (self.avg_doc_length or 1))
                score += idf * (tf * (self.k1 + 1)) / denominator

            if score > 0:
                if chunk.section.strip().lower() in LOW_VALUE_SECTIONS:
                    score *= 0.05
                scores.append(SearchResult(chunk=chunk, score=score))

        scores.sort(key=lambda item: item.score, reverse=True)
        return scores[:top_k]
