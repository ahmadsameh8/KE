"""Neo4j connection + query helper.

Loads credentials from .env, opens a single shared driver, and exposes
cypher() which returns a pandas DataFrame.
"""

import os
import pandas as pd
from dotenv import load_dotenv
from neo4j import GraphDatabase
from neo4j.graph import Node, Relationship, Path

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


# --------------------------------------------------------------------------- #
# Subgraph extraction (for visualisation)
#
# cypher() flattens everything to a DataFrame, which loses the graph
# structure. subgraph() instead keeps the Node / Relationship objects so the
# matched subgraph can be drawn.
# --------------------------------------------------------------------------- #

def _node_caption(node: Node) -> str:
    """Pick a human-readable label for a node."""
    props = dict(node)
    for key in ("caseTitle", "displayName", "name", "caseNumber"):
        val = props.get(key)
        if val not in (None, "", "null"):
            return str(val)
    labels = list(node.labels)
    return labels[0] if labels else "node"


def _as_node(node: Node) -> dict:
    labels = list(node.labels)
    return {
        "id": node.element_id,
        "label": labels[0] if labels else "Node",
        "caption": _node_caption(node),
        "properties": dict(node),
    }


def _as_edge(rel: Relationship) -> dict:
    return {
        "id": rel.element_id,
        "type": rel.type,
        "source": rel.start_node.element_id,
        "target": rel.end_node.element_id,
    }


def _collect(value, nodes: dict, edges: dict) -> None:
    """Walk a returned value and gather any nodes / relationships in it."""
    if isinstance(value, Node):
        nodes[value.element_id] = _as_node(value)
    elif isinstance(value, Relationship):
        # ensure both endpoints are present even if returned standalone
        if value.start_node is not None:
            nodes.setdefault(value.start_node.element_id, _as_node(value.start_node))
        if value.end_node is not None:
            nodes.setdefault(value.end_node.element_id, _as_node(value.end_node))
        edges[value.element_id] = _as_edge(value)
    elif isinstance(value, Path):
        for n in value.nodes:
            nodes[n.element_id] = _as_node(n)
        for r in value.relationships:
            _collect(r, nodes, edges)
    elif isinstance(value, (list, tuple)):
        for v in value:
            _collect(v, nodes, edges)
    elif isinstance(value, dict):
        for v in value.values():
            _collect(v, nodes, edges)


def subgraph(query: str, **params):
    """Run a Cypher query and extract the nodes + relationships it returns.

    Returns (nodes, edges) as lists of plain dicts, ready to be rendered.

    Example:
        nodes, edges = subgraph(
            "MATCH p=(c:Case {caseNumber:$n})-[r]-(x) RETURN p", n=2028)
    """
    nodes: dict = {}
    edges: dict = {}
    with _driver.session() as session:
        for record in session.run(query, **params):
            for value in record.values():
                _collect(value, nodes, edges)
    return list(nodes.values()), list(edges.values())


def run_explore(query: str, **params):
    """Run a query once and return everything needed to visualise it.

    Returns (nodes, edges, dataframe):
      - nodes/edges are populated when the query returns graph elements
        (paths / nodes / relationships) — ready for a graph render.
      - the DataFrame always holds the tabular form, so aggregate queries
        (counts, rankings) can be shown as a table or chart.
    """
    nodes: dict = {}
    edges: dict = {}
    rows: list = []
    with _driver.session() as session:
        for record in session.run(query, **params):
            for value in record.values():
                _collect(value, nodes, edges)
            rows.append(record.data())
    return list(nodes.values()), list(edges.values()), pd.DataFrame(rows)


if __name__ == "__main__":
    verify()
    print("Connected")
    print(cypher("MATCH (n) RETURN labels(n)[0] AS label, count(*) AS n "
"ORDER BY n DESC")) ## to test the connectivity