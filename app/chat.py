"""Streamlit chat UI for the EU Competition Cases graph.

Run with:
    uv run streamlit run app/chat.py
"""

import sys
from pathlib import Path

# So that `from src...` works when running streamlit from project root
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import streamlit as st
from src.chain import build_chain
from src.db import cypher


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


@st.cache_data(ttl=600, show_spinner=False)
def get_stats():
    """Quick stats for the sidebar — refreshed every 10 minutes."""
    df = cypher("""
        MATCH (n)
        RETURN labels(n)[0] AS label, count(*) AS count
        ORDER BY count DESC
    """)
    return df


chain = get_chain()


# ------------------------------- sidebar ----------------------------------- #

with st.sidebar:
    st.header("📊 Graph at a glance")
    stats = get_stats()
    for _, row in stats.iterrows():
        st.metric(row["label"], f"{row['count']:,}")

    st.divider()
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
        if msg.get("cypher"):
            with st.expander("View generated Cypher"):
                st.code(msg["cypher"], language="cypher")


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

        st.markdown(answer)
        if cypher_used:
            with st.expander("View generated Cypher"):
                st.code(cypher_used, language="cypher")

    st.session_state.messages.append({
        "role": "assistant",
        "content": answer,
        "cypher": cypher_used,
    })