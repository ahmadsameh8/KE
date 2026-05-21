# Test Questions

Each file contains a set of natural-language questions paired with the
**correct Cypher answer**. They are the ground truth for evaluating the
LLM-powered question-answering system.

Run any single query directly in Neo4j Browser, or use them inside the
test script in `tests/test_qa.py` to check whether the LLM produces an
equivalent query.

## Levels

| File | Theme | Difficulty |
|------|-------|------------|
| `level_1_simple_counts.cypher` | Single MATCH + count | ⭐ trivial |
| `level_2_top_n.cypher`         | ORDER BY + LIMIT (rankings) | ⭐⭐ easy |
| `level_3_filters.cypher`       | WHERE clauses, dates, conditions | ⭐⭐ easy |
| `level_4_aggregations.cypher`  | GROUP BY-style queries, averages | ⭐⭐⭐ medium |
| `level_5_multi_hop.cypher`     | Two-edge traversals (the graph's strength) | ⭐⭐⭐ medium |
| `level_6_specific_cases.cypher`| Detail lookups by case number / title | ⭐⭐⭐ medium |
| `level_7_hard.cypher`          | Ratios, conditional sums, growth rates | ⭐⭐⭐⭐ hard |
| `level_8_comparative.cypher`   | Side-by-side comparisons, UNIONs | ⭐⭐⭐⭐ hard |

## File format

Each file follows the same pattern:

```cypher
// Q1: A natural-language question
MATCH ...
RETURN ...;


// Q2: Another question
MATCH ...
RETURN ...;
```

The question comment is what you'd ask the LLM. The Cypher block is the
correct answer.

## Typical usage

1. Run a query yourself in Neo4j Browser to record the ground-truth result.
2. Ask the LLM the same natural-language question.
3. Compare:
   - Does the LLM's Cypher run without error?
   - Does it return the same value (or a value within tolerance)?

Tally pass/fail per level to see where the system breaks down. Failing
questions become candidate examples to add to the few-shot prompt in
`src/prompts.py`.
