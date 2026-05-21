// ============================================================================
// LEVEL 7 — Hard, multi-step questions
// ----------------------------------------------------------------------------
// These need multiple WITH stages, ratios, comparisons between subsets, or
// conditional aggregations. Good stress tests for the LLM — without
// few-shot examples in the prompt, expect roughly half of these to fail.
// ============================================================================


// Q1: What percentage of cases are mergers?
MATCH (c:Case)
WITH count(c) AS total,
     sum(CASE WHEN c.caseInstrument = 'Merger' THEN 1 ELSE 0 END) AS mergers
RETURN total,
       mergers,
       round(100.0 * mergers / total, 2) AS pct_mergers;


// Q2: Which company has the most antitrust cases against it?
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case {caseInstrument: 'Antitrust & Cartels'})
WHERE co.name <> 'null'
RETURN co.name AS company, count(c) AS antitrust_cases
ORDER BY antitrust_cases DESC
LIMIT 1;


// Q3: Which sector saw the biggest growth from the 2010s to the 2020s?
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
WHERE c.caseInitiationDate.year >= 2010
WITH s.name AS sector,
     sum(CASE WHEN c.caseInitiationDate.year < 2020 THEN 1 ELSE 0 END) AS cases_2010s,
     sum(CASE WHEN c.caseInitiationDate.year >= 2020 THEN 1 ELSE 0 END) AS cases_2020s
WHERE cases_2010s > 0
RETURN sector,
       cases_2010s,
       cases_2020s,
       round(100.0 * (cases_2020s - cases_2010s) / cases_2010s, 1) AS growth_pct
ORDER BY growth_pct DESC
LIMIT 10;


// Q4: Which sectors are most associated with private-equity firms
// (Blackstone, Carlyle, KKR, Apollo, Bain Capital, Cinven, Advent)?
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)-[:HAS_SECTION]->(s:Section)
WHERE co.name IN ['BLACKSTONE','CARLYLE','KKR','APOLLO','BAIN CAPITAL','CINVEN','ADVENT']
RETURN s.name AS sector, count(DISTINCT c) AS pe_cases
ORDER BY pe_cases DESC
LIMIT 10;


// Q5: Companies that appear in at least one case in every decade 1990s–2020s
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)
WHERE co.name <> 'null'
  AND c.caseInitiationDate IS NOT NULL
WITH co, collect(DISTINCT (c.caseInitiationDate.year / 10) * 10) AS decades
WHERE 1990 IN decades
  AND 2000 IN decades
  AND 2010 IN decades
  AND 2020 IN decades
RETURN co.name AS company, decades, size(decades) AS decade_count
ORDER BY company;


// Q6: Top sector for each case type (Merger vs Antitrust)
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
WITH c.caseInstrument AS instrument, s.name AS sector, count(c) AS cases
ORDER BY instrument, cases DESC
WITH instrument, collect({sector: sector, cases: cases})[0] AS top
RETURN instrument, top.sector AS top_sector, top.cases AS cases
ORDER BY cases DESC;


// Q7: What share of each company's cases are antitrust (top 10 by total cases)?
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)
WHERE co.name <> 'null'
WITH co,
     count(c) AS total_cases,
     sum(CASE WHEN c.caseInstrument = 'Antitrust & Cartels' THEN 1 ELSE 0 END) AS antitrust
WHERE total_cases >= 20
RETURN co.name AS company,
       total_cases,
       antitrust,
       round(100.0 * antitrust / total_cases, 1) AS antitrust_pct
ORDER BY total_cases DESC
LIMIT 10;


// Q8: Which year had the highest share of antitrust cases (vs mergers)?
MATCH (c:Case)
WHERE c.caseInitiationDate IS NOT NULL
WITH c.caseInitiationDate.year AS year,
     count(c) AS total,
     sum(CASE WHEN c.caseInstrument = 'Antitrust & Cartels' THEN 1 ELSE 0 END) AS antitrust
WHERE total >= 20
RETURN year,
       total,
       antitrust,
       round(100.0 * antitrust / total, 1) AS antitrust_pct
ORDER BY antitrust_pct DESC
LIMIT 5;
