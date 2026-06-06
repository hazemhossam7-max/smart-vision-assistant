# Website QA API Documentation

## Overview

This project is a Website Question Answering backend. It scrapes website pages, extracts readable text from useful HTML tags, chunks the text with metadata, retrieves relevant chunks with BM25, and returns extractive or short generated-style answers with source citations.

## Run

```powershell
python -m pip install -r requirements.txt
python -m website_qa.cli seed-demo
python -m website_qa.cli run --host 127.0.0.1 --port 8000
```

Open:

- Web UI: `http://127.0.0.1:8000/`
- Swagger docs: `http://127.0.0.1:8000/docs`
- Health: `http://127.0.0.1:8000/health`

## Endpoints

### GET `/health`

Returns service status and index size.

Example response:

```json
{
  "status": "ok",
  "pages": 2,
  "chunks": 3
}
```

### POST `/seed-demo`

Indexes built-in demo content so the API can answer immediately without internet access.

Example response:

```json
{
  "message": "Demo pages indexed",
  "added_chunks": 3,
  "pages": 2,
  "chunks": 3
}
```

### POST `/ingest`

Scrapes and indexes website content.

Request body:

```json
{
  "urls": ["https://gate.ahram.org.eg/"],
  "max_pages": 5,
  "reset": false
}
```

Fields:

- `urls`: one or more website URLs.
- `max_pages`: maximum number of pages to scrape, including same-domain links.
- `reset`: when `true`, clears the old index before adding new content.

Example response:

```json
{
  "message": "Website content indexed",
  "pages_scraped": 5,
  "added_chunks": 18,
  "pages": 5,
  "chunks": 18
}
```

### POST `/ask`

Answers a question from the indexed website content.

Request body:

```json
{
  "question": "What are the key steps to build a Website QA model?",
  "top_k": 4,
  "mode": "extractive"
}
```

Fields:

- `question`: user query.
- `top_k`: number of retrieved chunks to inspect.
- `mode`: `extractive` returns the best evidence sentence; `generative` combines top evidence sentences into a short response.

Example response:

```json
{
  "answer": "Data collection scrapes webpages, HTML parsing extracts meaningful tags, preprocessing cleans and chunks text, retrieval finds relevant paragraphs, and answer generation returns an extractive or summarized response.",
  "confidence": 0.57,
  "mode": "extractive",
  "sources": [
    {
      "url": "demo://assignment/website-qa",
      "title": "Website Question Answering Model",
      "section": "Key Steps",
      "score": 4.152,
      "snippet": "Data collection scrapes webpages..."
    }
  ]
}
```

## CLI Examples

```powershell
python -m website_qa.cli ingest https://www.egypttoday.com/ --max-pages 3 --reset
python -m website_qa.cli ask "What is this website about?" --mode generative
```

## Gemini Answer Generation

The system can use Gemini for better `generative` answers after retrieval. Scraping and retrieval still happen locally; Gemini only receives the top retrieved website evidence and writes a cleaner answer.

Create a `.env` file in the project root:

```powershell
copy .env.example .env
```

Open `.env` and paste your key:

```env
GEMINI_API_KEY=your_real_key_here
GEMINI_MODEL=gemini-1.5-flash
```

Restart the server after editing `.env`:

```powershell
python -m website_qa.cli run --host 127.0.0.1 --port 8000
```

Notes:

- `Extractive` mode always stays local.
- `Generative` mode uses Gemini only when `GEMINI_API_KEY` is set.
- If Gemini fails or the key is missing, the project falls back to local generation.

For JavaScript-heavy websites, install Scrapling browser dependencies and enable the dynamic fetcher:

```powershell
python -c "from scrapling.cli import install; install([], standalone_mode=False)"
$env:WEBSITE_QA_DYNAMIC_FETCH="1"
python -m website_qa.cli ingest https://example.com --max-pages 3 --reset
```

## Implementation Notes

- Scraping: Scrapling `Fetcher` is used first for browser-like HTTP fetching. `requests` remains as a fallback.
- Dynamic scraping: optional Scrapling `DynamicFetcher` can be enabled with `WEBSITE_QA_DYNAMIC_FETCH=1` after installing Scrapling browser dependencies.
- Parsing: removes scripts, styles, navigation, footer, forms, iframes, and other non-content tags.
- Preprocessing: text cleaning, tokenization, sentence splitting, chunking with overlap, metadata storage.
- Retrieval: local BM25 implementation.
- Answering: local extractive sentence scoring with a generated-style synthesis mode.
- Deployment: FastAPI with automatic Swagger documentation.
