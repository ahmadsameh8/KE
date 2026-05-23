# EU Competition Cases — Knowledge Graph Q&A

A natural-language question-answering system over a **Neo4j knowledge graph** of
**10,919 EU competition cases (1974–2026)**. Ask a question in plain English and
get back a written answer **and** an interactive graph of the nodes and
relationships the answer is based on.

Built with **LangChain + Google Gemini** (text-to-Cypher), **Neo4j**, and
**Streamlit**.

---

## What it does

- **Chat** — type a question (e.g. *"Which sectors does Blackstone operate in?"*).
  An LLM translates it to Cypher, runs it on the graph, and answers in natural
  language.
- **Graph of the answer** — alongside the text, the app draws the relevant
  subgraph (Cases, Companies, Sectors, Legal bases) as an interactive network.
- **Transparent** — every answer exposes the generated Cypher.

## The knowledge graph

| Node | Key properties |
|------|----------------|
| `Case` | caseNumber, caseTitle, caseInstrument, caseInitiationDate, caseLastDecisionDate |
| `Company` | name |
| `Section` | name, sectionCode, division, group, classCode, classDescription |
| `LegalBasis` | name |

Relationships: `(:Case)-[:INVOLVES_COMPANY]->(:Company)`,
`(:Case)-[:HAS_SECTION]->(:Section)`,
`(:Case)-[:HAS_LEGAL_BASIS]->(:LegalBasis)`.

`caseInstrument` is either `Merger` or `Antitrust & Cartels`.

---

## Repository structure

```
.
├── app/
│   └── chat.py                 # Streamlit chat UI (answer + inline graph)
├── src/
│   ├── chain.py                # LangChain GraphCypherQAChain (text answers)
│   ├── viz.py                  # NL → subgraph Cypher → interactive pyvis graph
│   ├── db.py                   # Neo4j driver + query / subgraph helpers
│   ├── prompts.py              # Few-shot prompts (QA + visualisation)
│   └── schema.py               # Graph schema handed to the LLM
├── cypher/
│   ├── build_KG_queries.cypher # LOAD CSV → builds the graph
│   └── visualize_KG_query.cypher
├── data/
│   └── cases.csv               # Graph input (10,919 cases)
├── test/                       # 8 leveled Cypher ground-truth test sets
├── notebooks/                  # Data pipeline + exploratory analysis
│   ├── data.ipynb              # merge raw case JSON
│   ├── Cleaning.ipynb          # raw JSON → cases.json → cases.csv
│   ├── analysis.ipynb          # exploratory data analysis
│   ├── knowledge_graph.ipynb   # graph construction / inspection
│   ├── Data/                   # raw EU case JSON (inputs)
│   └── cases.json, cases.csv   # intermediate / output
├── docs/
│   └── KE_Proposal.docx        # project proposal
├── .env.example                # template for required credentials
└── pyproject.toml
```

## Data pipeline (notebooks)

Raw EU case exports → cleaned, graph-ready CSV:

```
Data/case-data-*.json  ──(Cleaning.ipynb)──►  cases.json  ──►  cases.csv  ──►  Neo4j
```

`data.ipynb` merges the raw exports, `Cleaning.ipynb` extracts and normalises
the cases, `analysis.ipynb` explores the dataset, and `knowledge_graph.ipynb`
covers graph construction. Each notebook is self-contained with its data under
`notebooks/`.

---

## Setup

### Prerequisites
- Python ≥ 3.12 and [uv](https://docs.astral.sh/uv/) (`pip install uv`)
- A running **Neo4j** instance (local Neo4j Desktop/Docker, or Neo4j Aura)
- A **Google Gemini API key** — https://aistudio.google.com/apikey

### 1. Configure credentials
```bash
cp .env.example .env      # then edit .env with your values
```
`.env` holds `URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD`, `GOOGLE_API_KEY`.
It is gitignored — never commit it.

### 2. Build the graph (one time)
Run [`cypher/build_KG_queries.cypher`](cypher/build_KG_queries.cypher) inside
Neo4j:
- **Local Neo4j** — copy `data/cases.csv` into Neo4j's `import/` folder, then run
  the script (it reads `file:///cases.csv`).
- **Neo4j Aura** — `file:///` is not available; change the first line to load
  from a URL, e.g.
  `LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ahmadsameh8/KE/main/data/cases.csv' AS row`.

Verify the load:
```cypher
MATCH (n) RETURN labels(n)[0] AS label, count(*) ORDER BY count(*) DESC;
```

### 3. Run the app
```bash
uv run streamlit run app/chat.py
```
Opens at http://localhost:8501. `uv run` installs all dependencies on first run.

Quick connectivity checks:
```bash
uv run python -m src.db       # prints "Connected" + node counts
uv run python -m src.chain    # answers a sample question (needs the API key)
```

---

## Testing

`test/` holds natural-language questions paired with their **correct Cypher**,
graded by difficulty (`level_1` simple counts → `level_8` comparative). Use them
as ground truth: ask the LLM each question and compare its Cypher / result. See
[`test/README.md`](test/README.md).

## Configuration notes

- LLM models are set in `src/chain.py` (text answers) and `src/viz.py` (graph
  queries) and can be swapped for any model your Gemini key supports.
- The graph is read-only for the app; loading is a separate, explicit step.
