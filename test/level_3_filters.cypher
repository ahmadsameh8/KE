// ============================================================================
// LEVEL 3 — Filters and conditions
// ----------------------------------------------------------------------------
// Adds WHERE clauses, date comparisons, and combined criteria.
// Tests whether the LLM correctly translates conditions like
// "between 2015 and 2020" or "antitrust ... in manufacturing".
// ============================================================================


// Q1: How many cases were initiated in 2020?
MATCH (c:Case)
WHERE c.caseInitiationDate.year = 2020
RETURN count(c) AS cases_in_2020;


// Q2: How many cases were initiated between 2015 and 2020 (inclusive)?
MATCH (c:Case)
WHERE c.caseInitiationDate.year >= 2015
  AND c.caseInitiationDate.year <= 2020
RETURN count(c) AS cases_2015_to_2020;


// Q3: How many antitrust cases occurred in the manufacturing sector?
MATCH (c:Case {caseInstrument: 'Antitrust & Cartels'})-[:HAS_SECTION]->(s:Section)
WHERE toUpper(s.name) = 'MANUFACTURING'
RETURN count(c) AS manufacturing_antitrust;


// Q4: List merger cases involving Goldman Sachs after 2015
MATCH (c:Case {caseInstrument: 'Merger'})-[:INVOLVES_COMPANY]->(co:Company)
WHERE toLower(co.name) = toLower('GOLDMAN SACHS')
  AND c.caseInitiationDate.year > 2015
RETURN c.caseNumber AS number,
       c.caseTitle AS title,
       c.caseInitiationDate AS started
ORDER BY c.caseInitiationDate DESC;


// Q5: How many cases cite Article 102?
MATCH (c:Case)-[:HAS_LEGAL_BASIS]->(l:LegalBasis {name: 'Art. 102'})
RETURN count(c) AS art_102_cases;


// Q6: Which companies appear in antitrust cases but NOT in merger cases?
MATCH (co:Company)<-[:INVOLVES_COMPANY]-(c:Case {caseInstrument: 'Antitrust & Cartels'})
WHERE co.name <> 'null'
  AND NOT EXISTS {
      MATCH (co)<-[:INVOLVES_COMPANY]-(:Case {caseInstrument: 'Merger'})
  }
RETURN co.name AS company
ORDER BY company
LIMIT 25;


// Q7: How many cases were initiated before the year 2000?
MATCH (c:Case)
WHERE c.caseInitiationDate.year < 2000
RETURN count(c) AS cases_before_2000;


// Q8: List cases in the "Information and Communication" sector decided in 2023
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
WHERE toUpper(s.name) = 'INFORMATION AND COMMUNICATION'
  AND c.caseLastDecisionDate.year = 2023
RETURN c.caseNumber AS number,
       c.caseTitle  AS title,
       c.caseLastDecisionDate AS decided
ORDER BY c.caseLastDecisionDate DESC;
