"""
rag/retriever.py

ROLE: Given a contract (or a specific suspicious pattern found in it), query
the vector store built by embed_and_store.py to retrieve the most relevant
historical exploits, so Sonnet's reasoning can be grounded in real precedent.

The retrieved candidates are NOT assumed relevant just because they're the
top-K nearest by embedding distance -- router/haiku_router.gate_rag_context()
is meant to filter these further before they reach Sonnet. This module's job
is only "find plausible candidates," not "decide what's actually relevant."

NOT VERIFIED end-to-end: this depends on embed_and_store.py's knowledge
base build, which itself failed in this sandbox due to a network
restriction (see that module's docstring). The query logic here follows
chromadb's documented API correctly, but has not been run against a real,
successfully-built collection. Build the knowledge base first (with
network access), then test this against a real reentrancy-pattern query
before trusting the "dao_hack.txt comes back as the top result" claim --
that's the expected behavior given the embeddings, not a confirmed one.
"""

import os
import chromadb
from rag.embed_and_store import _get_embedding_model, _COLLECTION_NAME, _DEFAULT_DB_PATH


def retrieve_relevant_exploits(query: str, top_k: int = 3, db_path: str = _DEFAULT_DB_PATH) -> list[str]:
    """
    Embed `query` (typically the contract source, or a specific flagged
    pattern description) and return the top_k most similar historical
    exploit write-ups from the knowledge base.

    Raises a clear error if the knowledge base hasn't been built yet,
    rather than returning an empty list that could be mistaken for "no
    relevant exploits found" -- those are different situations and
    shouldn't look the same to the caller.
    """
    if not os.path.exists(db_path):
        raise RuntimeError(
            f"Knowledge base not found at {db_path}. "
            "Run `python -m rag.embed_and_store` first to build it."
        )

    model = _get_embedding_model()
    query_embedding = model.encode([query], show_progress_bar=False).tolist()

    chroma_client = chromadb.PersistentClient(path=db_path)
    collection = chroma_client.get_collection(_COLLECTION_NAME)

    results = collection.query(query_embeddings=query_embedding, n_results=top_k)
    documents = results.get("documents", [[]])[0]
    return documents
