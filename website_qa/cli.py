from __future__ import annotations

import argparse
import json
import sys

import uvicorn

from .qa import build_answer
from .retrieval import BM25Retriever
from .scraper import scrape_urls
from .seed import DEMO_PAGES
from .store import DocumentStore


def seed_demo(args: argparse.Namespace) -> None:
    store = DocumentStore(args.index)
    added = store.add_pages(DEMO_PAGES)
    print(json.dumps({"added_chunks": added, **store.stats()}, ensure_ascii=False, indent=2))


def ingest(args: argparse.Namespace) -> None:
    store = DocumentStore(args.index)
    if args.reset:
        store.clear()
    pages = scrape_urls(args.urls, max_pages=args.max_pages)
    added = store.add_pages(pages)
    print(json.dumps({"pages_scraped": len(pages), "added_chunks": added, **store.stats()}, ensure_ascii=False, indent=2))


def ask(args: argparse.Namespace) -> None:
    store = DocumentStore(args.index)
    if not store.chunks:
        store.add_pages(DEMO_PAGES)
    retriever = BM25Retriever(store.chunks)
    result = build_answer(args.question, retriever, mode=args.mode, top_k=args.top_k)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def run(args: argparse.Namespace) -> None:
    uvicorn.run("website_qa.api:app", host=args.host, port=args.port, reload=args.reload)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Website QA model CLI")
    parser.add_argument("--index", default="data/website_qa_index.json", help="Path to the persisted JSON index")
    subparsers = parser.add_subparsers(dest="command", required=True)

    seed_parser = subparsers.add_parser("seed-demo", help="Index built-in demo content")
    seed_parser.set_defaults(func=seed_demo)

    ingest_parser = subparsers.add_parser("ingest", help="Scrape and index website URLs")
    ingest_parser.add_argument("urls", nargs="+")
    ingest_parser.add_argument("--max-pages", type=int, default=5)
    ingest_parser.add_argument("--reset", action="store_true")
    ingest_parser.set_defaults(func=ingest)

    ask_parser = subparsers.add_parser("ask", help="Ask a question against the indexed website content")
    ask_parser.add_argument("question")
    ask_parser.add_argument("--top-k", type=int, default=4)
    ask_parser.add_argument("--mode", choices=["extractive", "generative"], default="extractive")
    ask_parser.set_defaults(func=ask)

    run_parser = subparsers.add_parser("run", help="Start the FastAPI server")
    run_parser.add_argument("--host", default="127.0.0.1")
    run_parser.add_argument("--port", type=int, default=8000)
    run_parser.add_argument("--reload", action="store_true")
    run_parser.set_defaults(func=run)

    return parser


def main() -> None:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
