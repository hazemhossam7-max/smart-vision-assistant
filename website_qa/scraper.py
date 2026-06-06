from __future__ import annotations

import os
from dataclasses import dataclass
from html import unescape
from typing import Iterable
from urllib.parse import urldefrag, urljoin, urlparse

import requests
import urllib3
from bs4 import BeautifulSoup
from requests.exceptions import SSLError
from urllib3.exceptions import InsecureRequestWarning

from .text import clean_text


REQUEST_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
    "Cache-Control": "no-cache",
}
SESSION = requests.Session()
SESSION.trust_env = False
urllib3.disable_warnings(InsecureRequestWarning)
NO_PROXY = {"http": "", "https": ""}
TEXT_TAGS = {"p", "li", "td", "th", "blockquote"}
SECTION_TAGS = {"h1", "h2", "h3", "h4", "h5", "h6"}
REMOVE_TAGS = {
    "script",
    "style",
    "noscript",
    "svg",
    "canvas",
    "iframe",
    "form",
    "nav",
    "footer",
    "aside",
}


@dataclass(frozen=True)
class PageContent:
    url: str
    title: str
    text: str
    sections: list[tuple[str, str]]


def fetch_html(url: str, timeout: int = 15) -> str:
    try:
        return fetch_html_with_scrapling(url, timeout=timeout)
    except Exception:
        if os.getenv("WEBSITE_QA_DYNAMIC_FETCH", "").lower() in {"1", "true", "yes"}:
            try:
                return fetch_html_with_scrapling_browser(url, timeout=timeout)
            except Exception:
                pass
        return fetch_html_with_requests(url, timeout=timeout)


def fetch_html_with_scrapling(url: str, timeout: int = 15) -> str:
    from scrapling.fetchers import Fetcher

    try:
        response = Fetcher.get(
            url,
            timeout=timeout,
            headers=REQUEST_HEADERS,
            proxies=NO_PROXY,
            stealthy_headers=True,
        )
    except Exception:
        response = Fetcher.get(
            url,
            timeout=timeout,
            headers=REQUEST_HEADERS,
            proxies=NO_PROXY,
            stealthy_headers=True,
            verify=False,
        )

    status = getattr(response, "status", 200)
    if status >= 400:
        raise ValueError(f"{url} returned HTTP {status}")

    headers = getattr(response, "headers", {}) or {}
    content_type = headers.get("content-type", "")
    if content_type and "html" not in content_type.lower():
        raise ValueError(f"{url} did not return HTML content")

    body = getattr(response, "body", b"")
    if isinstance(body, bytes):
        return body.decode("utf-8", errors="replace")
    return str(body)


def fetch_html_with_scrapling_browser(url: str, timeout: int = 15) -> str:
    from scrapling.fetchers import DynamicFetcher

    response = DynamicFetcher.fetch(
        url,
        headless=True,
        network_idle=True,
        block_ads=True,
        disable_resources=True,
        timeout=timeout * 1000,
    )

    status = getattr(response, "status", 200)
    if status >= 400:
        raise ValueError(f"{url} returned HTTP {status}")

    body = getattr(response, "body", b"")
    if isinstance(body, bytes):
        return body.decode("utf-8", errors="replace")
    return str(body)


def fetch_html_with_requests(url: str, timeout: int = 15) -> str:
    try:
        response = SESSION.get(
            url,
            timeout=timeout,
            headers=REQUEST_HEADERS,
        )
    except SSLError:
        response = SESSION.get(
            url,
            timeout=timeout,
            headers=REQUEST_HEADERS,
            verify=False,
        )
    response.raise_for_status()
    content_type = response.headers.get("content-type", "")
    if "html" not in content_type.lower():
        raise ValueError(f"{url} did not return HTML content")
    response.encoding = response.apparent_encoding or response.encoding
    return response.text


def extract_page(url: str, html: str) -> PageContent:
    soup = BeautifulSoup(html, "lxml")
    for tag in soup.find_all(REMOVE_TAGS):
        tag.decompose()

    title = clean_text(unescape(soup.title.get_text(" ", strip=True))) if soup.title else url
    sections: list[tuple[str, str]] = []
    current_section = ""
    current_parts: list[str] = []
    all_parts: list[str] = []

    body = soup.body or soup
    for tag in body.find_all([*SECTION_TAGS, *TEXT_TAGS]):
        text = clean_text(unescape(tag.get_text(" ", strip=True)))
        if not text:
            continue

        if tag.name in SECTION_TAGS:
            if current_parts:
                sections.append((current_section, " ".join(current_parts)))
                current_parts = []
            current_section = text
            all_parts.append(text)
            continue

        current_parts.append(text)
        all_parts.append(text)

    if current_parts:
        sections.append((current_section, " ".join(current_parts)))

    page_text = clean_text(" ".join(all_parts))
    return PageContent(url=url, title=title, text=page_text, sections=sections)


def discover_same_domain_links(base_url: str, html: str, limit: int) -> list[str]:
    base = urlparse(base_url)
    soup = BeautifulSoup(html, "lxml")
    links: list[str] = []
    seen = {base_url}

    for anchor in soup.find_all("a", href=True):
        href = urldefrag(urljoin(base_url, anchor["href"]))[0]
        parsed = urlparse(href)
        if parsed.scheme not in {"http", "https"}:
            continue
        if parsed.netloc != base.netloc:
            continue
        if href in seen:
            continue
        seen.add(href)
        links.append(href)
        if len(links) >= limit:
            break

    return links


def scrape_urls(urls: Iterable[str], *, max_pages: int = 5) -> list[PageContent]:
    pages: list[PageContent] = []
    queue = list(dict.fromkeys(urls))
    seen: set[str] = set()

    while queue and len(pages) < max_pages:
        url = queue.pop(0)
        if url in seen:
            continue
        seen.add(url)

        html = fetch_html(url)
        page = extract_page(url, html)
        if page.text:
            pages.append(page)

        remaining = max_pages - len(pages)
        if remaining > 0:
            queue.extend(discover_same_domain_links(url, html, remaining))

    return pages
