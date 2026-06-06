from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[1]

load_dotenv(PROJECT_ROOT / ".env")
load_dotenv(Path(__file__).with_name("api.env"))

DEFAULT_MODEL = "gemini-1.5-flash"


def is_gemini_enabled() -> bool:
    return bool(os.getenv("GEMINI_API_KEY"))


def generate_answer_with_gemini(
    *,
    question: str,
    evidence: str,
    language_hint: str,
    model_name: str | None = None,
) -> str | None:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return None

    try:
        import google.generativeai as genai

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel(model_name or os.getenv("GEMINI_MODEL", DEFAULT_MODEL))
        prompt = _build_prompt(question=question, evidence=evidence, language_hint=language_hint)
        response = model.generate_content(prompt)
        answer = (getattr(response, "text", "") or "").strip()
        return answer or None
    except Exception:
        return None


def _build_prompt(*, question: str, evidence: str, language_hint: str) -> str:
    language_rule = (
        "Answer in Arabic."
        if language_hint == "ar"
        else "Answer in the same language as the useful evidence, unless the question clearly asks otherwise."
    )
    return f"""
You are a website question answering assistant.
Use only the website evidence below.
Do not add facts that are not supported by the evidence.
If the evidence is not enough, say that the website content does not contain the answer.
{language_rule}
Write a clear, direct answer. Avoid mentioning sources, chunks, retrieval, or metadata.

Question:
{question}

Website evidence:
{evidence}
""".strip()
