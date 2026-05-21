"""Build the LangChain GraphCypherQAChain.

Wires together:
  - Neo4jGraph  (wraps the database)
  - ChatGoogleGenerativeAI (Gemini)
  - the few-shot prompt from src.prompts
"""

import os
from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph, GraphCypherQAChain
from langchain_google_genai import ChatGoogleGenerativeAI

from .schema import SCHEMA
from .prompts import cypher_prompt

load_dotenv()


def build_chain(
    model: str = "gemma-3-27b-it",
    temperature: float = 0.0,
    verbose: bool = False,
):
    """Return a ready-to-use GraphCypherQAChain.

    Example:
        chain = build_chain()
        chain.invoke({"query": "How many cases are in the dataset?"})
    """

    if not os.getenv("GOOGLE_API_KEY"):
        raise RuntimeError(
            "GOOGLE_API_KEY not set. Add it to your .env file."
        )
   
    graph = Neo4jGraph(
        url=os.getenv("URI"),
        username=os.getenv("NEO4J_USERNAME"),
        password=os.getenv("NEO4J_PASSWORD"),
        refresh_schema=False,
    )
    graph.schema = SCHEMA

    llm = ChatGoogleGenerativeAI(model=model, temperature=temperature)

    return GraphCypherQAChain.from_llm(
        llm=llm,
        graph=graph,
        cypher_prompt=cypher_prompt,
        verbose=verbose,
        allow_dangerous_requests=True,
        return_intermediate_steps=True,
    )


def ask(chain, question: str) -> dict:
    """Convenience wrapper. Returns {answer, cypher}."""
    result = chain.invoke({"query": question})
    return {
        "answer": result["result"],
        "cypher": result["intermediate_steps"][0]["query"]
                  if result.get("intermediate_steps") else None,
    }


if __name__ == "__main__":
    # Quick smoke test: `uv run python -m src.chain`
    chain = build_chain(verbose=True)
    out = ask(chain, "How many cases are in the dataset?")
    print("\n", out["answer"])