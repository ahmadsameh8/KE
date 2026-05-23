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

Two interfaces are included: a **Streamlit chatbot** (this app) and a **NeoDash
dashboard** on Neo4j Aura that turns natural-language requests into Cypher and
renders graph / table / chart panels.

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
│   └── cases.csv               # Graph input 
├── test/                       
├── notebooks/                  # Data pipeline + exploratory analysis
│   ├── Cleaning.ipynb          # raw JSON → cases.json → cases.csv
│   ├── analysis.ipynb          # exploratory data analysis
│   ├── Data/                   # raw EU case JSON (inputs)
│ 
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

### 2. Set up Neo4j and build the graph (one time)

Host the graph either locally with **Neo4j Desktop** or in the cloud with
**Neo4j Aura**. Build it once — the app only reads from it afterwards.

#### Build the KG on Neo4j Desktop (local)

1. Download and install **Neo4j Desktop** — https://neo4j.com/download/.
2. Create a database: **+ New** → **Create project**, then inside the project
   **Add → Local DBMS**. Give it a name, set a **password** (remember it), pick a
   recent version, and click **Create**.
3. **Start** the DBMS (press ▶). Once it's running, the Bolt address is
   `neo4j://127.0.0.1:7687` and the user is `neo4j`.
4. Make the CSV reachable by `LOAD CSV`: click the DBMS → the **`…`** menu →
   **Open folder → Import**, and copy this repo's `data/cases.csv` into that
   `import/` folder.
5. Open **Neo4j Browser** (the **Open** button) or the **Query** tab.
6. Paste the contents of
   [`cypher/build_KG_queries.cypher`](cypher/build_KG_queries.cypher) and run it.
   It reads `file:///cases.csv` from the import folder you just used.
7. (Optional) run [`cypher/visualize_KG_query.cypher`](cypher/visualize_KG_query.cypher)
   to see the graph in Browser.
8. Put the local connection in your `.env`:
   ```env
   URI=neo4j://127.0.0.1:7687
   NEO4J_USERNAME=neo4j
   NEO4J_PASSWORD=<the password you set in step 2>
   ```

### 3. Run the chatbot (the Streamlit app)

The Streamlit app is the **chatbot**: ask a question in plain English and get a
written answer plus an interactive graph of the nodes/relationships behind it.
It works against whichever instance you configured in `.env` — local **Neo4j
Desktop** or cloud **Neo4j Aura** — no code change needed; only the
`URI`/credentials differ.

```bash
uv run streamlit run app/chat.py
```
Opens at http://localhost:8501. `uv run` installs all dependencies on first run.

Quick connectivity checks:
```bash
uv run python -m src.db       # prints "Connected" + node counts
uv run python -m src.chain    # answers a sample question (needs the API key)
```

> **Tip:** the chatbot runs against either instance — build/develop locally on
> Neo4j Desktop, or point `.env` at Neo4j Aura for a cloud graph.

### 4. Explore on Neo4j Aura with NeoDash (natural-language dashboard)

A second interface: a **NeoDash** dashboard on a **Neo4j Aura** graph, where you
type questions in natural language, NeoDash's AI translates them into Cypher, and
the results render as interactive **graph / table / chart** panels.

**a. Put the graph on Aura.** Create a free instance at
https://console.neo4j.io and save the credentials (user `neo4j`, URI
`neo4j+s://<id>.databases.neo4j.io`). Aura has no import folder, so load the CSV
from a URL — open the Aura **Query** tab, paste
[`cypher/build_KG_queries.cypher`](cypher/build_KG_queries.cypher), and change its
first line to:
```cypher
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/ahmadsameh8/KE/staging/data/cases.csv' AS row
```

**b. Open NeoDash and connect to Aura.** Launch NeoDash
(https://neodash.graphapp.io, or from Neo4j Desktop / the Aura console), choose
**New dashboard**, and connect with your Aura details (protocol `neo4j+s`, host
`<id>.databases.neo4j.io`, port `7687`, database `neo4j`, user `neo4j`, your
password).

**c. Enable natural-language reports.** In NeoDash **Settings**, turn on the AI
assistant and provide an LLM provider API key (e.g. OpenAI).

**d. Build the dashboard.** Add a report → choose **"generate query with AI"** →
type a question in English (e.g. *"Top 10 sectors by number of cases"*). NeoDash
generates the Cypher; pick a visualization (Graph, Table, Bar chart, …) and the
panel renders. Repeat to assemble a multi-panel dashboard.

> Aura Free instances pause after a few days idle (and are deleted after ~30 days
> paused) — resume from the console if NeoDash can't connect.

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
