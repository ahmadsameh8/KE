SCHEMA = """
Node properties:
- Case {caseNumber: INTEGER, caseTitle: STRING, caseInstrument: STRING,
        caseInitiationDate: DATE, caseLastDecisionDate: DATE,
        displayName: STRING}
- Company {name: STRING, displayName: STRING}
- Section {name: STRING, sectionCode: STRING, division: INTEGER,
           group: INTEGER, classCode: INTEGER, classDescription: STRING,
           displayName: STRING}
- LegalBasis {name: STRING, displayName: STRING}

Relationships:
(:Case)-[:INVOLVES_COMPANY]->(:Company)
(:Case)-[:HAS_SECTION]->(:Section)
(:Case)-[:HAS_LEGAL_BASIS]->(:LegalBasis)

Notes:
- caseInstrument is either 'Merger' or 'Antitrust & Cartels'.
- Company.name 'null' represents missing data and should be excluded.
- One Case typically links to multiple Companies and may cite multiple
  LegalBasis articles, but maps to exactly one Section.
"""