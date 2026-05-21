"""Neo4j connection + query helper.

Loads credentials from .env, opens a single shared driver, and exposes
cypher() which returns a pandas DataFrame.
"""

import os
import pandas as pd
from dotenv import load_dotenv
from neo4j import GraphDatabase

load_dotenv()

URI      = os.getenv("URI")
USERNAME = os.getenv("NEO4J_USERNAME")
PASSWORD = os.getenv("NEO4J_PASSWORD")

if not PASSWORD:
    raise RuntimeError(
        "NEO4J_PASSWORD not set. Add it to your .env file."
    )

# One driver, shared across the whole app
_driver = GraphDatabase.driver(URI, auth=(USERNAME, PASSWORD))


def cypher(query: str, **params) -> pd.DataFrame:
    """Run a Cypher query and return the result as a DataFrame.

    Example:
        df = cypher("MATCH (c:Case) RETURN count(c) AS n")
        df = cypher("MATCH (c:Case {caseNumber:$n}) RETURN c", n=2028)
    """
    with _driver.session() as session:
        result = session.run(query, **params)
        return pd.DataFrame([record.data() for record in result])


def verify() -> None:
    """Raise if the database is unreachable."""
    _driver.verify_connectivity()


def close() -> None:
    """Close the driver. Call at the end of a script."""
    _driver.close()


if __name__ == "__main__":
    verify()
    print("Connected")
    print(cypher("MATCH (n) RETURN labels(n)[0] AS label, count(*) AS n "
"ORDER BY n DESC")) ## to test the connectivity