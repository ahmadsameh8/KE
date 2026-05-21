// ============================================================================
// LEVEL 2 — Top-N lists
// ----------------------------------------------------------------------------
// Ranking queries. They use ORDER BY ... DESC LIMIT N and require the LLM
// to pick the right aggregation. Most systems handle these well.
// ============================================================================


// Q1: Which 10 companies appear in the most cases?
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)
WHERE co.name <> 'null'
RETURN co.name AS company, count(c) AS cases
ORDER BY cases DESC
LIMIT 10;


// Q2: What are the top 5 industry sectors by case count?
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
RETURN s.name AS sector, count(c) AS cases
ORDER BY cases DESC
LIMIT 5;


// Q3: Which legal articles are cited most often?
MATCH (c:Case)-[:HAS_LEGAL_BASIS]->(l:LegalBasis)
RETURN l.name AS article, count(c) AS cases
ORDER BY cases DESC;


// Q4: List 10 case titles that involve Siemens
MATCH (c:Case)-[:INVOLVES_COMPANY]->(co:Company)
WHERE toLower(co.name) = toLower('SIEMENS')
RETURN c.caseNumber AS number, c.caseTitle AS title
LIMIT 10;


// Q5: Show me the most recent 10 cases (by initiation date)
MATCH (c:Case)
WHERE c.caseInitiationDate IS NOT NULL
RETURN c.caseNumber AS number,
       c.caseTitle AS title,
       c.caseInitiationDate AS started
ORDER BY c.caseInitiationDate DESC
LIMIT 10;


// Q6: Which 5 cases have the most companies involved?
MATCH (c:Case)-[:INVOLVES_COMPANY]->(co:Company)
WHERE co.name <> 'null'
WITH c, count(co) AS n
RETURN c.caseNumber AS number, c.caseTitle AS title, n AS companies
ORDER BY n DESC
LIMIT 5;


// Q7: Top 5 companies in merger cases only
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case {caseInstrument: 'Merger'})
WHERE co.name <> 'null'
RETURN co.name AS company, count(c) AS merger_cases
ORDER BY merger_cases DESC
LIMIT 5;


// Q8: Top 5 companies in antitrust cases only
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case {caseInstrument: 'Antitrust & Cartels'})
WHERE co.name <> 'null'
RETURN co.name AS company, count(c) AS antitrust_cases
ORDER BY antitrust_cases DESC
LIMIT 5;
