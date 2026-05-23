"""Build and render the subgraph behind an answer.

Given a natural-language question, ask the LLM for a Cypher query that returns
a small subgraph (paths), run it, and render an interactive graph so the user
can see the nodes and relationships the answer is based on.
"""

import os
import re

from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI

from .schema import SCHEMA
from .prompts import viz_prompt
from .db import subgraph

load_dotenv()

# Colour per node label — keeps the rendered graph readable.
_COLORS = {
    "Case": "#4C78A8",
    "Company": "#F58518",
    "Section": "#54A24B",
    "LegalBasis": "#E45756",
}

_llm = None


def _get_llm(model: str = "gemini-3.1-flash-lite-preview"):
    """Lazily create a single shared LLM for visualisation queries."""
    global _llm
    if _llm is None:
        if not os.getenv("GOOGLE_API_KEY"):
            raise RuntimeError(
                "GOOGLE_API_KEY not set. Add it to your .env file."
            )
        _llm = ChatGoogleGenerativeAI(model=model, temperature=0.0)
    return _llm


def _clean(text) -> str:
    """Normalise LLM output to a string and strip markdown fences.

    Gemini returns message.content as a list of parts (strings or
    {"type": "text", "text": ...} dicts), so flatten that first.
    """
    if isinstance(text, list):
        text = "".join(
            part if isinstance(part, str) else part.get("text", "")
            for part in text
        )
    text = str(text).strip()
    text = re.sub(r"^```(?:cypher)?", "", text).strip()
    text = re.sub(r"```$", "", text).strip()
    return text


def subgraph_cypher(question: str, model: str = "gemini-3.1-flash-lite-preview") -> str:
    """Ask the LLM for a path-returning Cypher query for visualisation."""
    prompt = viz_prompt.format(schema=SCHEMA, question=question)
    resp = _get_llm(model).invoke(prompt)
    return _clean(resp.content)


def subgraph_for_question(question: str, model: str = "gemini-3.1-flash-lite-preview"):
    """Return (cypher, nodes, edges) for the subgraph behind an answer."""
    query = subgraph_cypher(question, model)
    nodes, edges = subgraph(query)
    return query, nodes, edges


def to_html(nodes, edges, height: str = "500px") -> str:
    """Render nodes/edges as an interactive pyvis network (HTML string)."""
    from pyvis.network import Network

    # cdn_resources="remote" is required so the vis-network JS loads from a CDN
    # rather than missing local files when embedded in Streamlit.
    net = Network(
        height=height,
        width="100%",
        directed=True,
        bgcolor="#ffffff",
        font_color="#222222",
        cdn_resources="remote",
    )
    net.barnes_hut()

    for n in nodes:
        net.add_node(
            n["id"],
            label=n["caption"],
            color=_COLORS.get(n["label"], "#9D9D9D"),
            title=f'{n["label"]}: {n["caption"]}',
        )
    for e in edges:
        net.add_edge(e["source"], e["target"], label=e["type"])

    try:
        return net.generate_html(notebook=False)
    except TypeError:  # older pyvis signatures
        return net.generate_html()


if __name__ == "__main__":
    # Quick smoke test: `uv run python -m src.viz`
    q, nodes, edges = subgraph_for_question("Tell me about case 2028")
    print("Cypher:\n", q)
    print(f"\n{len(nodes)} nodes, {len(edges)} relationships")
