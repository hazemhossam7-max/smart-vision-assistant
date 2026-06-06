from website_qa.qa import build_answer
from website_qa.api import AskRequest, ask, store as api_store
from website_qa.retrieval import BM25Retriever
from website_qa.scraper import extract_page
from website_qa.scraper import PageContent
from website_qa.seed import DEMO_PAGES
from website_qa.store import DocumentStore


def test_extract_page_removes_scripts_and_keeps_content():
    html = """
    <html><head><title>Example</title><script>bad()</script></head>
    <body><nav>menu</nav><h1>Main</h1><p>Useful website text for question answering.</p></body></html>
    """
    page = extract_page("https://example.com", html)

    assert page.title == "Example"
    assert "Useful website text" in page.text
    assert "bad" not in page.text
    assert "menu" not in page.text


def test_demo_answer_returns_source(tmp_path):
    store = DocumentStore(tmp_path / "index.json")
    store.add_pages(DEMO_PAGES)

    answer = build_answer(
        "What are the key steps to build a website QA model?",
        BM25Retriever(store.chunks),
    )

    assert answer["confidence"] > 0
    assert answer["sources"]
    assert "Data collection" in answer["answer"]


def test_arabic_question_matches_english_museum_content(tmp_path):
    store = DocumentStore(tmp_path / "index.json")
    store.add_pages(DEMO_PAGES)

    answer = build_answer(
        "ما هي فئات المواقع في المشروع؟",
        BM25Retriever(store.chunks),
    )

    assert answer["confidence"] > 0
    assert answer["answer_language"] == "en"
    assert "news" in answer["answer"]
    assert answer["sources"][0]["title"] == "Sample Egyptian Websites"


def test_arabic_question_returns_arabic_when_source_is_arabic(tmp_path):
    store = DocumentStore(tmp_path / "index.json")
    store.add_pages(
        [
            PageContent(
                url="https://example.com/ar",
                title="موقع المتحف",
                text="",
                sections=[
                    (
                        "عن المتحف",
                        "المتحف المصري هو متحف تاريخي في القاهرة يضم مجموعة كبيرة من الآثار المصرية القديمة.",
                    )
                ],
            )
        ]
    )

    answer = build_answer("ما هو المتحف المصري؟", BM25Retriever(store.chunks))

    assert answer["answer_language"] == "ar"
    assert "متحف تاريخي" in answer["answer"]


def test_extractive_and_generative_are_different(tmp_path):
    store = DocumentStore(tmp_path / "index.json")
    store.add_pages(
        [
            PageContent(
                url="https://example.com/egyptian-museum",
                title="Egyptian Museum",
                text="",
                sections=[
                    (
                        "Egyptian Museum",
                        "The Museum of Egyptian Antiquities, commonly known as the Egyptian Museum, "
                        "is a national history museum in Cairo, Egypt. An Egyptological museum, it "
                        "houses the largest collection of Egyptian antiquities in the world, including "
                        "over 170,000 items.",
                    )
                ],
            )
        ]
    )

    retriever = BM25Retriever(store.chunks)
    answer = build_answer("What is the Egyptian Museum?", retriever, mode="extractive")
    detailed_answer = build_answer("What is the Egyptian Museum?", retriever, mode="generative")

    assert answer["answer_language"] == "en"
    assert "national history museum" in answer["answer"]
    assert "170,000" not in answer["answer"]
    assert "170,000" in detailed_answer["answer"]
    assert len(detailed_answer["answer"]) > len(answer["answer"])
    assert detailed_answer["generator"] == "local"


def test_arabic_transliterated_name_matches_english_source(tmp_path):
    store = DocumentStore(tmp_path / "index.json")
    store.add_pages(
        [
            PageContent(
                url="https://example.com/ronaldo",
                title="Cristiano Ronaldo",
                text="",
                sections=[
                    (
                        "Cristiano Ronaldo",
                        "Cristiano Ronaldo dos Santos Aveiro is a Portuguese professional footballer "
                        "who plays as a forward and captains the Portugal national team.",
                    )
                ],
            )
        ]
    )

    answer = build_answer("من هو كريستيانو رونالدو؟", BM25Retriever(store.chunks))

    assert answer["confidence"] > 0
    assert "Portuguese professional footballer" in answer["answer"]


def test_arabic_who_is_question_prefers_definition_sentence(tmp_path):
    store = DocumentStore(tmp_path / "index.json")
    store.add_pages(
        [
            PageContent(
                url="https://example.com/ar/ronaldo",
                title="كريستيانو رونالدو",
                text="",
                sections=[
                    (
                        "حياته الشخصية",
                        "تبرع رونالدو لجمعية خيرية في ماديرا وتحدثت الصحف عن حياته الشخصية.",
                    ),
                    (
                        "كريستيانو رونالدو",
                        "كريستيانو رونالدو دوس سانتوس أفيرو هو لاعب كرة قدم برتغالي يلعب في مركز الهجوم.",
                    ),
                ],
            )
        ]
    )

    answer = build_answer("من هو اللاعب كريستيانو رونالدو؟", BM25Retriever(store.chunks))

    assert "هو لاعب كرة قدم برتغالي" in answer["answer"]


def test_api_does_not_fallback_to_demo_when_index_is_empty(tmp_path):
    old_path = api_store.path
    old_chunks = api_store.chunks
    try:
        api_store.path = tmp_path / "empty.json"
        api_store.chunks = []
        api_store.save()

        response = ask(AskRequest(question="What is this website?"))

        assert response["confidence"] == 0.0
        assert "No website content is indexed" in response["answer"]
    finally:
        api_store.path = old_path
        api_store.chunks = old_chunks
