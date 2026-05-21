// ============================================================================
// LEVEL 8 — Comparative questions
// ----------------------------------------------------------------------------
// Side-by-side comparisons. Each query computes two parallel counts so the
// reader can see the contrast in a single row / table.
// ============================================================================


// Q1: Compare merger vs antitrust activity in the manufacturing sector
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
WHERE toUpper(s.name) = 'MANUFACTURING'
RETURN c.caseInstrument AS type, count(c) AS cases
ORDER BY cases DESC;


// Q2: Compare Goldman Sachs and Blackstone (cases, sectors, partners)
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)
WHERE co.name IN ['GOLDMAN SACHS', 'BLACKSTONE']
OPTIONAL MATCH (c)-[:HAS_SECTION]->(s:Section)
OPTIONAL MATCH (c)-[:INVOLVES_COMPANY]->(other:Company)
WHERE other.name <> co.name AND other.name <> 'null'
RETURN co.name AS company,
       count(DISTINCT c) AS cases,
       count(DISTINCT s) AS sectors_touched,
       count(DISTINCT other) AS distinct_partners
ORDER BY cases DESC;


// Q3: Which sector has a higher antitrust-to-merger ratio:
//     Manufacturing or Information & Communication?
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
WHERE toUpper(s.name) IN ['MANUFACTURING', 'INFORMATION AND COMMUNICATION']
WITH s.name AS sector,
     sum(CASE WHEN c.caseInstrument = 'Merger' THEN 1 ELSE 0 END) AS mergers,
     sum(CASE WHEN c.caseInstrument = 'Antitrust & Cartels' THEN 1 ELSE 0 END) AS antitrust
RETURN sector,
       mergers,
       antitrust,
       round(100.0 * antitrust / (mergers + antitrust), 2) AS antitrust_pct_of_total
ORDER BY antitrust_pct_of_total DESC;


// Q4: Cases per decade, broken out by case type
MATCH (c:Case)
WHERE c.caseInitiationDate IS NOT NULL
WITH (c.caseInitiationDate.year / 10) * 10 AS decade,
     c.caseInstrument AS instrument,
     count(*) AS cases
RETURN decade, instrument, cases
ORDER BY decade, instrument;


// Q5: Pre- vs post-2010 sector activity (top 10 sectors with biggest shift)
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
WHERE c.caseInitiationDate IS NOT NULL
WITH s.name AS sector,
     sum(CASE WHEN c.caseInitiationDate.year < 2010 THEN 1 ELSE 0 END) AS pre_2010,
     sum(CASE WHEN c.caseInitiationDate.year >= 2010 THEN 1 ELSE 0 END) AS post_2010
RETURN sector, pre_2010, post_2010, (post_2010 - pre_2010) AS change
ORDER BY change DESC
LIMIT 10;


// Q6: Top 3 most-active companies in mergers vs in antitrust (side by side)
CALL {
    MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case {caseInstrument: 'Merger'})
    WHERE co.name <> 'null'
    RETURN co.name AS company, count(c) AS cases, 'Merger' AS instrument
    ORDER BY cases DESC LIMIT 3
}
RETURN instrument, company, cases
UNION
CALL {
    MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case {caseInstrument: 'Antitrust & Cartels'})
    WHERE co.name <> 'null'
    RETURN co.name AS company, count(c) AS cases, 'Antitrust & Cartels' AS instrument
    ORDER BY cases DESC LIMIT 3
}
RETURN instrument, company, cases;


// Q7: Average case duration: merger vs antitrust
MATCH (c:Case)
WHERE c.caseInitiationDate IS NOT NULL
  AND c.caseLastDecisionDate IS NOT NULL
WITH c.caseInstrument AS instrument,
     duration.between(c.caseInitiationDate, c.caseLastDecisionDate).days AS days
RETURN instrument,
       count(*) AS cases,
       round(avg(days)) AS avg_days,
       round(percentileCont(days, 0.5)) AS median_days
ORDER BY avg_days DESC;


// Q8: For each of the top 5 sectors, show the dominant legal article
MATCH (s:Section)<-[:HAS_SECTION]-(c:Case)
WITH s, count(c) AS sector_cases
ORDER BY sector_cases DESC
LIMIT 5
MATCH (s)<-[:HAS_SECTION]-(c:Case)-[:HAS_LEGAL_BASIS]->(l:LegalBasis)
WITH s.name AS sector, l.name AS article, count(c) AS cases
ORDER BY sector, cases DESC
WITH sector, collect({article: article, cases: cases})[0] AS top
RETURN sector, top.article AS dominant_article, top.cases AS cases
ORDER BY cases DESC;
