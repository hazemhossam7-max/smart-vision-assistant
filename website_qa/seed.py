from __future__ import annotations

from .scraper import PageContent


DEMO_PAGES = [
    PageContent(
        url="demo://assignment/website-qa",
        title="Website Question Answering Model",
        text=(
            "A Website Question Answering model extracts and generates answers from website content "
            "based on user queries. The pipeline starts with web scraping using BeautifulSoup, Scrapy, "
            "or Selenium. HTML parsing extracts useful text from paragraphs, headings, lists, and tables "
            "while removing scripts, navigation, ads, and repeated layout text. Preprocessing cleans text, "
            "splits it into chunks, and stores metadata such as page title, section headers, and links. "
            "The retrieval layer can use BM25 or dense vector search to find relevant paragraphs. "
            "The answer layer can be extractive, returning exact text, or generative, producing a short "
            "answer from retrieved evidence. A practical deployment exposes endpoints with Flask or FastAPI."
        ),
        sections=[
            (
                "Key Steps",
                "Data collection scrapes webpages, HTML parsing extracts meaningful tags, preprocessing "
                "cleans and chunks text, retrieval finds relevant paragraphs, and answer generation returns "
                "an extractive or summarized response.",
            ),
            (
                "Deployment",
                "The student should submit API documentation. The backend can be deployed as a FastAPI "
                "service with endpoints for indexing website URLs and asking questions.",
            ),
        ],
    ),
    PageContent(
        url="demo://samples/egyptian-websites",
        title="Sample Egyptian Websites",
        text=(
            "Example sources for the project include news websites such as Youm7, Masrawy, Ahram Gate, "
            "Gomhuria Online, and Egypt Today. University and public-service sources can include Cairo "
            "University, Alexandria University, E-JUST, Al-Azhar, Dar Al-Ifta, Islamweb, EgyptAir, "
            "Study in Egypt, and the Grand Egyptian Museum. E-commerce examples include Amazon, Noon, "
            "and Jumia."
        ),
        sections=[
            (
                "Website Categories",
                "The sample categories are news, universities, e-commerce, sports, religious services, "
                "travel, education, and museums.",
            )
        ],
    ),
]
