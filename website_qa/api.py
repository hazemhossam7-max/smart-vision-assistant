from __future__ import annotations

from typing import Literal

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field, HttpUrl

from .qa import build_answer
from .retrieval import BM25Retriever
from .scraper import scrape_urls
from .seed import DEMO_PAGES
from .store import DocumentStore


app = FastAPI(
    title="Website QA API",
    description="Scrape websites, index text chunks, and answer user questions with citations.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

store = DocumentStore()


class IngestRequest(BaseModel):
    urls: list[HttpUrl] = Field(..., min_length=1)
    max_pages: int = Field(5, ge=1, le=30)
    reset: bool = False


class AskRequest(BaseModel):
    question: str = Field(..., min_length=2)
    top_k: int = Field(4, ge=1, le=10)
    mode: Literal["extractive", "generative"] = "extractive"


@app.get("/", response_class=HTMLResponse)
def home() -> str:
    return """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Website QA</title>
  <style>
    body { margin: 0; font-family: Arial, sans-serif; background: #f7f8fb; color: #1f2937; }
    main { max-width: 920px; margin: 40px auto; padding: 0 20px; }
    section { background: white; border: 1px solid #d9dee8; border-radius: 8px; padding: 20px; margin-bottom: 16px; }
    textarea, input, select { width: 100%; box-sizing: border-box; border: 1px solid #cbd5e1; border-radius: 6px; padding: 10px; font: inherit; }
    button { background: #185abc; color: white; border: 0; border-radius: 6px; padding: 10px 14px; font-weight: 700; cursor: pointer; }
    button.secondary { background: #2f3a4a; }
    .row { display: grid; grid-template-columns: 1fr 150px; gap: 12px; align-items: end; }
    .option { display: flex; gap: 8px; align-items: center; margin-top: 12px; font-size: 15px; }
    .option input { width: auto; }
    pre { white-space: pre-wrap; background: #101827; color: #e5e7eb; padding: 16px; border-radius: 8px; overflow: auto; }
    h1 { font-size: 28px; margin: 0 0 18px; }
    h2 { font-size: 18px; margin: 0 0 12px; }
  </style>
</head>
<body>
<main>
  <h1>Website QA</h1>
  <section>
    <h2>Ask</h2>
    <textarea id="question" rows="3">What are the key steps to build a Website QA model?</textarea>
    <div class="row" style="margin-top: 12px">
      <select id="mode"><option value="extractive">Extractive</option><option value="generative">Generative</option></select>
      <button onclick="ask()">Ask</button>
    </div>
  </section>
  <section>
    <h2>Ingest URLs</h2>
    <textarea id="urls" rows="3" placeholder="https://example.com"></textarea>
    <label class="option"><input id="resetIndex" type="checkbox" checked> Replace old index</label>
    <div class="row" style="margin-top: 12px">
      <input id="maxPages" type="number" min="1" max="30" value="3">
      <button class="secondary" onclick="ingest()">Ingest</button>
    </div>
  </section>
  <section><h2>Result</h2><pre id="result">Ready.</pre></section>
</main>
<script>
async function ask() {
  result.textContent = 'Searching the indexed website...';
  const body = { question: question.value, mode: mode.value, top_k: 4 };
  const res = await fetch('/ask', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body) });
  const data = await res.json();
  result.textContent = data.answer || data.detail || JSON.stringify(data, null, 2);
}
async function ingest() {
  result.textContent = 'Indexing website content...';
  const body = { urls: urls.value.split(/\\s+/).filter(Boolean), max_pages: Number(maxPages.value), reset: resetIndex.checked };
  const res = await fetch('/ingest', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body) });
  const data = await res.json();
  if (!res.ok) {
    result.textContent = data.detail || 'Could not index this website.';
    return;
  }
  result.textContent = `Indexed ${data.pages_scraped} page(s) and ${data.chunks} text chunk(s). You can ask a question now.`;
}
</script>
</body>
</html>
"""


@app.get("/health")
def health() -> dict:
    return {"status": "ok", **store.stats()}


@app.post("/seed-demo")
def seed_demo() -> dict:
    added = store.add_pages(DEMO_PAGES)
    return {"message": "Demo pages indexed", "added_chunks": added, **store.stats()}


@app.post("/ingest")
def ingest(request: IngestRequest) -> dict:
    if request.reset:
        store.clear()
    try:
        pages = scrape_urls([str(url) for url in request.urls], max_pages=request.max_pages)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Could not scrape website: {exc}") from exc

    added = store.add_pages(pages)
    return {"message": "Website content indexed", "pages_scraped": len(pages), "added_chunks": added, **store.stats()}


@app.post("/ask")
def ask(request: AskRequest) -> dict:
    store.load()
    if not store.chunks:
        return {
            "answer": "No website content is indexed yet. Paste a website URL, click Ingest, then ask your question.",
            "confidence": 0.0,
            "mode": request.mode,
            "sources": [],
        }

    retriever = BM25Retriever(store.chunks)
    return build_answer(request.question, retriever, mode=request.mode, top_k=request.top_k)
