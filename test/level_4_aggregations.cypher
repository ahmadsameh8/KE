// ============================================================================
// LEVEL 4 — Aggregations and grouping
// ----------------------------------------------------------------------------
// Multi-row aggregations: GROUP BY equivalents in Cypher (the implicit
// grouping by all non-aggregated return values), date bucketing, averages,
// and durations.
// ============================================================================


// Q1: How many cases per year since 2000?
MATCH (c:Case)
WHERE c.caseInitiationDate.year >= 2000
RETURN c.caseInitiationDate.year AS year, count(c) AS cases
ORDER BY year;


// Q2: What is the average number of companies per merger case?
MATCH (c:Case {caseInstrument: 'Merger'})
OPTIONAL MATCH (c)-[:INVOLVES_COMPANY]->(co:Company)
WHERE co.name <> 'null'
WITH c, count(co) AS n
RETURN round(avg(n), 2) AS avg_companies_per_merger;


// Q3: How many cases are there in each industry sector?
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
RETURN s.name AS sector, count(c) AS cases
ORDER BY cases DESC;


// Q4: Group cases by decade and case type
MATCH (c:Case)
WHERE c.caseInitiationDate IS NOT NULL
WITH (c.caseInitiationDate.year / 10) * 10 AS decade,
     c.caseInstrument AS instrument
RETURN decade, instrument, count(*) AS cases
ORDER BY decade, instrument;


// Q5: Average case duration (days) by case type
MATCH (c:Case)
WHERE c.caseInitiationDate IS NOT NULL
  AND c.caseLastDecisionDate IS NOT NULL
WITH c.caseInstrument AS instrument,
     duration.between(c.caseInitiationDate, c.caseLastDecisionDate).days AS days
RETURN instrument,
       count(*) AS cases,
       round(avg(days)) AS avg_days,
       min(days) AS min_days,
       max(days) AS max_days
ORDER BY avg_days DESC;


// Q6: Number of distinct sectors each company has appeared in (top 15)
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case)-[:HAS_SECTION]->(s:Section)
WHERE co.name <> 'null'
RETURN co.name AS company,
       count(DISTINCT s) AS sectors_touched,
       count(DISTINCT c) AS total_cases
ORDER BY sectors_touched DESC, total_cases DESC
LIMIT 15;


// Q7: Distribution of how many companies are named per case
MATCH (c:Case)
OPTIONAL MATCH (c)-[:INVOLVES_COMPANY]->(co:Company)
WHERE co.name <> 'null'
WITH c, count(co) AS n
RETURN n AS companies_in_case, count(c) AS number_of_cases
ORDER BY companies_in_case;


// Q8: Average number of legal bases cited per case, by case type
MATCH (c:Case)
OPTIONAL MATCH (c)-[:HAS_LEGAL_BASIS]->(l:LegalBasis)
WITH c, count(l) AS bases
RETURN c.caseInstrument AS instrument,
       round(avg(bases), 2) AS avg_legal_bases
ORDER BY avg_legal_bases DESC;
