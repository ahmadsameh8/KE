// ============================================================================
// LEVEL 6 — Specific case lookups
// ----------------------------------------------------------------------------
// Detail queries about individual cases or a small named set. Useful for
// "show me everything about X" interactions.
// ============================================================================


// Q1: Tell me about case 2028 (all its connections)
MATCH (c:Case {caseNumber: 2028})
OPTIONAL MATCH (c)-[:INVOLVES_COMPANY]->(co:Company)
WHERE co.name <> 'null'
OPTIONAL MATCH (c)-[:HAS_SECTION]->(s:Section)
OPTIONAL MATCH (c)-[:HAS_LEGAL_BASIS]->(l:LegalBasis)
RETURN c.caseNumber       AS number,
       c.caseTitle        AS title,
       c.caseInstrument   AS instrument,
       c.caseInitiationDate    AS started,
       c.caseLastDecisionDate  AS decided,
       collect(DISTINCT co.name) AS companies,
       collect(DISTINCT s.name)  AS sectors,
       collect(DISTINCT l.name)  AS legal_bases;


// Q2: What companies were in case 7217?
MATCH (c:Case {caseNumber: 7217})-[:INVOLVES_COMPANY]->(co:Company)
WHERE co.name <> 'null'
RETURN c.caseTitle AS case, collect(co.name) AS companies;


// Q3: Which cases involve BOTH EDF and Siemens?
MATCH (c:Case)-[:INVOLVES_COMPANY]->(co1:Company)
WHERE toLower(co1.name) = toLower('EDF')
MATCH (c)-[:INVOLVES_COMPANY]->(co2:Company)
WHERE toLower(co2.name) = toLower('SIEMENS')
RETURN c.caseNumber AS number,
       c.caseTitle AS title,
       c.caseInitiationDate AS started;


// Q4: Find cases in the "Water supply" sector
MATCH (c:Case)-[:HAS_SECTION]->(s:Section)
WHERE toLower(s.name) CONTAINS 'water supply'
RETURN c.caseNumber AS number,
       c.caseTitle  AS title,
       c.caseInitiationDate AS started
ORDER BY c.caseInitiationDate DESC
LIMIT 25;


// Q5: Which cases combine Article 101 and Article 102?
MATCH (c:Case)-[:HAS_LEGAL_BASIS]->(l1:LegalBasis {name: 'Art. 101'})
MATCH (c)-[:HAS_LEGAL_BASIS]->(l2:LegalBasis {name: 'Art. 102'})
RETURN c.caseNumber AS number,
       c.caseTitle  AS title,
       c.caseInstrument AS type
ORDER BY c.caseInitiationDate DESC
LIMIT 25;


// Q6: Show all cases initiated on a specific date (e.g. 2020-06-15)
MATCH (c:Case)
WHERE c.caseInitiationDate = date('2020-06-15')
RETURN c.caseNumber AS number,
       c.caseTitle AS title,
       c.caseInstrument AS type;


// Q7: Cases with the word "ENERGY" in the title (top 10)
MATCH (c:Case)
WHERE toUpper(c.caseTitle) CONTAINS 'ENERGY'
RETURN c.caseNumber AS number,
       c.caseTitle AS title,
       c.caseInitiationDate AS started
ORDER BY c.caseInitiationDate DESC
LIMIT 10;


// Q8: List all distinct legal bases used in case number 1886
MATCH (c:Case {caseNumber: 1886})-[:HAS_LEGAL_BASIS]->(l:LegalBasis)
RETURN c.caseTitle AS case, collect(DISTINCT l.name) AS legal_bases;
