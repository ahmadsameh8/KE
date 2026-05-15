LOAD CSV WITH HEADERS FROM 'file:///cases.csv' AS row
// --- Create Case node ---
MERGE (c:Case {caseNumber: row.caseNumber})
SET 
    c.caseTitle = row.caseTitle,
    c.caseInstrument = row.caseInstrument,
    c.caseLastDecisionDate =
        CASE 
            WHEN row.caseLastDecisionDate IS NOT NULL AND row.caseLastDecisionDate <> 'null' 
            THEN date(substring(row.caseLastDecisionDate, 0, 10))
            ELSE NULL
        END,
    c.caseInitiationDate =
        CASE 
            WHEN row.caseInitiationDate IS NOT NULL AND row.caseInitiationDate <> 'null' 
            THEN date(substring(row.caseInitiationDate, 0, 10))
            ELSE NULL
        END,
    c.decisionLabel = row.decisionLabel,
    c.displayName = row.caseTitle

// --- Create Section node ---
MERGE (s:Section {name: row.sectionName})
SET 
    s.sectionCode = row.sectionCode,
    s.division = row.division,
    s.group = row.group,
    s.classCode = row.classCode,
    s.classDescription = row.classDescription,
    s.displayName = row.sectionName
MERGE (c)-[:HAS_SECTION]->(s)

// --- Create LegalBasis nodes ---
WITH c, row
WITH c, SPLIT(row.caseLegalBasisLabel, ';') AS bases, row
UNWIND bases AS base
WITH c, row, TRIM(base) AS lb
WHERE lb IS NOT NULL AND lb <> ''
MERGE (l:LegalBasis {name: lb})
SET l.displayName = lb
MERGE (c)-[:HAS_LEGAL_BASIS]->(l)

// --- Create Company nodes ---
WITH c, row
WITH c, SPLIT(row.caseCompanies, ';') AS companies, row
UNWIND companies AS company
WITH c, TRIM(company) AS comp
WHERE comp IS NOT NULL AND comp <> ''
MERGE (co:Company {name: comp})
SET co.displayName = comp
MERGE (c)-[:INVOLVES_COMPANY]->(co);
