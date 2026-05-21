// ============================================================================
// LEVEL 5 — Two-hop / relational questions
// ----------------------------------------------------------------------------
// These are where graphs shine over a flat table. They traverse two edges:
// Company -> Case -> Section, Company -> Case -> Company, etc.
// The LLM must understand that intermediate nodes connect the endpoints.
// ============================================================================


// Q1: Which sectors does Blackstone operate in?
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)-[:HAS_SECTION]->(s:Section)
WHERE toLower(co.name) = toLower('BLACKSTONE')
RETURN s.name AS sector, count(DISTINCT c) AS cases
ORDER BY cases DESC;


// Q2: Which companies co-appear with Goldman Sachs most often?
MATCH (g:Company)<-[:INVOLVES_COMPANY]-(c:Case)-[:INVOLVES_COMPANY]->(other:Company)
WHERE toLower(g.name) = toLower('GOLDMAN SACHS')
  AND other.name <> g.name
  AND other.name <> 'null'
RETURN other.name AS partner, count(c) AS shared_cases
ORDER BY shared_cases DESC
LIMIT 10;


// Q3: In which sectors does Article 101 get cited most?
MATCH (l:LegalBasis {name: 'Art. 101'})<-[:HAS_LEGAL_BASIS]-(c:Case)-[:HAS_SECTION]->(s:Section)
RETURN s.name AS sector, count(c) AS cases
ORDER BY cases DESC
LIMIT 10;


// Q4: Which companies are most diversified across sectors (top 10)?
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)-[:HAS_SECTION]->(s:Section)
WHERE co.name <> 'null'
RETURN co.name AS company,
       count(DISTINCT s) AS sectors,
       count(DISTINCT c) AS cases
ORDER BY sectors DESC, cases DESC
LIMIT 10;


// Q5: Find all companies that appeared in cases together with Siemens
MATCH (s:Company)<-[:INVOLVES_COMPANY]-(c:Case)-[:INVOLVES_COMPANY]->(other:Company)
WHERE toLower(s.name) = toLower('SIEMENS')
  AND other.name <> s.name
  AND other.name <> 'null'
RETURN DISTINCT other.name AS partner, count(c) AS shared_cases
ORDER BY shared_cases DESC
LIMIT 20;


// Q6: Which legal articles are most associated with the manufacturing sector?
MATCH (s:Section)<-[:HAS_SECTION]-(c:Case)-[:HAS_LEGAL_BASIS]->(l:LegalBasis)
WHERE toUpper(s.name) = 'MANUFACTURING'
RETURN l.name AS article, count(c) AS cases
ORDER BY cases DESC;


// Q7: Top 10 company pairs that appear together in the most cases
MATCH (a:Company)<-[:INVOLVES_COMPANY]-(c:Case)-[:INVOLVES_COMPANY]->(b:Company)
WHERE a.name < b.name
  AND a.name <> 'null'
  AND b.name <> 'null'
RETURN a.name AS company_a, b.name AS company_b, count(c) AS shared_cases
ORDER BY shared_cases DESC
LIMIT 10;


// Q8: For each sector, which company appears most (top performer per sector)?
MATCH (s:Section)<-[:HAS_SECTION]-(c:Case)-[:INVOLVES_COMPANY]->(co:Company)
WHERE co.name <> 'null'
WITH s.name AS sector, co.name AS company, count(c) AS cases
ORDER BY sector, cases DESC
WITH sector, collect({company: company, cases: cases})[0] AS top
RETURN sector, top.company AS top_company, top.cases AS cases
ORDER BY cases DESC;
