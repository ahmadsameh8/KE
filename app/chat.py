"""Streamlit chat UI for the EU Competition Cases graph.

Run with:
    uv run streamlit run app/chat.py
"""

import sys
from pathlib import Path

# So that `from src...` works when running streamlit from project root
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import streamlit as st
import streamlit.components.v1 as components
from src.chain import build_chain
from src.viz import subgraph_for_question, to_html


# ----------------------------- page config --------------------------------- #

st.set_page_config(
    page_title="EU Competition Cases — Graph Chat",
    page_icon="⚖️",
    layout="wide",
)

st.title("⚖️ EU Competition Cases — Ask the Graph")
st.caption(
    "Natural-language questions over a Neo4j knowledge graph of "
    "10,919 EU competition cases (1974–2026)."
)


# --------------------------- cached resources ------------------------------ #

@st.cache_resource(show_spinner="Connecting to graph and LLM…")
def get_chain():
    return build_chain(verbose=False)


chain = get_chain()


# ------------------------------ render helpers ----------------------------- #

def render_extras(msg: dict) -> None:
    """Render the answer's graph inline, plus the Cypher in a details panel."""
    # The graph of the retrieved answer — shown right under the text answer.
    if msg.get("graph_html"):
        st.markdown(
            f"**🕸️ Graph of the answer** — {msg.get('graph_n', 0)} nodes, "
            f"{msg.get('graph_e', 0)} relationships"
        )
        components.html(msg["graph_html"], height=500, scrolling=True)
    elif msg.get("graph_error"):
        st.caption(f"⚠️ Couldn't build the graph: {msg['graph_error']}")

    # Cypher tucked away so it doesn't crowd the answer + graph.
    if msg.get("cypher") or msg.get("viz_cypher"):
        with st.expander("View Cypher"):
            if msg.get("cypher"):
                st.caption("Answer query")
                st.code(msg["cypher"], language="cypher")
            if msg.get("viz_cypher"):
                st.caption("Graph query")
                st.code(msg["viz_cypher"], language="cypher")


# ------------------------------- sidebar ----------------------------------- #

with st.sidebar:
    st.subheader("💡 Try asking")
    examples = [
        "How many cases are in the dataset?",
        "Which 5 companies appear in the most cases?",
        "Top sectors by case count",
        "How many antitrust cases in 2020?",
        "Which sectors does Blackstone operate in?",
        "Tell me about case 2028",
        "What percentage of cases are mergers?",
    ]
    for ex in examples:
        if st.button(ex, key=f"ex_{ex}", use_container_width=True):
            st.session_state["queued_question"] = ex

    st.divider()
    show_graph = st.toggle(
        "🕸️ Show answer subgraph",
        value=True,
        help="Also draw the nodes and relationships each answer is based on.",
    )
    if st.button("🗑️ Clear chat", use_container_width=True):
        st.session_state.messages = []
        st.rerun()


# --------------------------- conversation state ---------------------------- #

if "messages" not in st.session_state:
    st.session_state.messages = []

# Re-render the existing conversation
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])
        if msg["role"] == "assistant":
            render_extras(msg)


# ---------------------- handle the next user message ---------------------- #

# Either typed-in or clicked from sidebar examples
question = st.chat_input("Ask about the graph…")
if not question and st.session_state.get("queued_question"):
    question = st.session_state.pop("queued_question")

if question:
    st.session_state.messages.append({"role": "user", "content": question})
    with st.chat_message("user"):
        st.markdown(question)

    with st.chat_message("assistant"):
        try:
            with st.spinner("Thinking…"):
                result = chain.invoke({"query": question})
            answer = result["result"]
            cypher_used = (
                result["intermediate_steps"][0]["query"]
                if result.get("intermediate_steps") else None
            )
        except Exception as e:
            answer = f"⚠️ Sorry, I couldn't answer that.\n\n```\n{e}\n```"
            cypher_used = None

        # Build the graph of the retrieved answer (best-effort).
        viz_cypher, graph_html = None, None
        graph_n, graph_e, graph_error = 0, 0, None
        if show_graph and cypher_used:
            try:
                with st.spinner("Building graph…"):
                    viz_cypher, nodes, edges = subgraph_for_question(question)
                if nodes:
                    graph_html = to_html(nodes, edges)
                    graph_n, graph_e = len(nodes), len(edges)
                else:
                    graph_error = "the query returned no nodes to draw."
            except Exception as e:
                graph_error = str(e)

        st.markdown(answer)
        msg = {
            "role": "assistant",
            "content": answer,
            "cypher": cypher_used,
            "viz_cypher": viz_cypher,
            "graph_html": graph_html,
            "graph_n": graph_n,
            "graph_e": graph_e,
            "graph_error": graph_error,
        }
        render_extras(msg)

    st.session_state.messages.append(msg)