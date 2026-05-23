from langchain_core.prompts import PromptTemplate

## we can add more. it is not the final edition

CYPHER_TEMPLATE = """Task: Generate a Cypher query for a Neo4j graph database.

Schema:
{schema}

Rules:
- Use only the labels and relationships in the schema.
- For company names use toLower() for case-insensitive matching.
- For year filters use c.caseInitiationDate.year = 2020 (not strings).
- Always exclude Company nodes where name = 'null'.
- Return ONLY the Cypher query, no markdown fences, no commentary.

Examples:

Q: How many cases are in the dataset?
Cypher: MATCH (c:Case) RETURN count(c) AS cases

Q: How many merger cases?
Cypher: MATCH (c:Case {{caseInstrument: 'Merger'}}) RETURN count(c) AS cases

Q: Top 5 companies by case count
Cypher: MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)
WHERE co.name <> 'null'
RETURN co.name AS company, count(c) AS cases
ORDER BY cases DESC LIMIT 5

Q: How many antitrust cases in 2020?
Cypher: MATCH (c:Case)
WHERE c.caseInstrument = 'Antitrust & Cartels'
  AND c.caseInitiationDate.year = 2020
RETURN count(c) AS cases


Question: {question}
Cypher:"""


cypher_prompt = PromptTemplate(
    input_variables=["schema", "question"],
    template=CYPHER_TEMPLATE,
)


# --------------------------------------------------------------------------- #
# Visualisation prompt
#
# The QA prompt above usually returns scalars (counts, names), which can't be
# drawn. This prompt instead asks for a small SUBGRAPH (paths) so we can show
# the nodes and relationships the answer is based on.
# --------------------------------------------------------------------------- #

VIZ_TEMPLATE = """Task: Generate a Cypher query that returns a small SUBGRAPH
(nodes and relationships) relevant to the question, for visualization.

Schema:
{schema}

Rules:
- RETURN whole nodes and relationships through a path variable, e.g. RETURN p.
- NEVER return aggregates, counts, or scalar values — only paths/nodes/rels.
- Always add LIMIT (default 25, never above 50) so the graph stays readable.
- Use only the labels and relationships in the schema.
- For company names use toLower() for case-insensitive matching.
- Always exclude Company nodes where name = 'null'.
- Return ONLY the Cypher query, no markdown fences, no commentary.

Examples:

Q: Tell me about case 2028
Cypher: MATCH p=(c:Case {{caseNumber: 2028}})-[r]-(n)
RETURN p LIMIT 50

Q: Which 5 companies appear in the most cases?
Cypher: MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)
WHERE co.name <> 'null'
WITH co, count(c) AS cases
ORDER BY cases DESC LIMIT 5
MATCH p=(co)<-[:INVOLVES_COMPANY]-(c2:Case)
RETURN p LIMIT 40

Q: Which sectors does Blackstone operate in?
Cypher: MATCH p=(co:Company)<-[:INVOLVES_COMPANY]-(c:Case)-[:HAS_SECTION]->(s:Section)
WHERE toLower(co.name) = 'blackstone'
RETURN p LIMIT 30

Q: How many merger cases?
Cypher: MATCH p=(c:Case {{caseInstrument: 'Merger'}})-[:INVOLVES_COMPANY]->(co:Company)
WHERE co.name <> 'null'
RETURN p LIMIT 25


Question: {question}
Cypher:"""


viz_prompt = PromptTemplate(
    input_variables=["schema", "question"],
    template=VIZ_TEMPLATE,
)