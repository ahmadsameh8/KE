// ============================================================================
// LEVEL 1 — Simple counts
// ----------------------------------------------------------------------------
// The easiest questions. Each one is a single MATCH + count.
// These should ALWAYS pass — if any fail, something is wrong with your setup.
// ============================================================================


// Q1: How many cases are in the dataset?
MATCH (c:Case)
RETURN count(c) AS cases;


// Q2: How many companies are in the graph?
MATCH (co:Company)
WHERE co.name <> 'null'
RETURN count(co) AS companies;


// Q3: How many merger cases are there?
MATCH (c:Case {caseInstrument: 'Merger'})
RETURN count(c) AS merger_cases;


// Q4: How many antitrust cases are there?
MATCH (c:Case {caseInstrument: 'Antitrust & Cartels'})
RETURN count(c) AS antitrust_cases;


// Q5: How many industry sections exist?
MATCH (s:Section)
RETURN count(s) AS sections;


// Q6: How many legal basis articles are referenced?
MATCH (l:LegalBasis)
RETURN count(l) AS legal_basis_articles;


// Q7: How many relationships of type INVOLVES_COMPANY are in the graph?
MATCH ()-[r:INVOLVES_COMPANY]->()
RETURN count(r) AS company_links;


// Q8: How many distinct case instruments (types) exist?
MATCH (c:Case)
RETURN count(DISTINCT c.caseInstrument) AS distinct_instruments;
