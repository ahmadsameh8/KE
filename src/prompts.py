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