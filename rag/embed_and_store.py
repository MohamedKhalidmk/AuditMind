"""
rag/embed_and_store.py

ROLE: Build the vector store (knowledge base) of historical smart contract
exploits, so Sonnet's reasoning can be grounded in real precedent instead of
generic explanations.

Uses ChromaDB (local, persistent, no external service needed) with
sentence-transformers for embeddings -- same embedding model choice as
smartune's duplicate detection (all-MiniLM-L6-v2: fast, free, local, no API
cost, appropriate for this small a knowledge base).

VERIFIED: chromadb and sentence-transformers install and import correctly.

NOT VERIFIED end-to-end: actually downloading and running the
all-MiniLM-L6-v2 model requires network access to huggingface.co, which is
blocked in the development sandbox this was written in -- the model
download itself failed there with a connection error. The chromadb
collection-building logic (create/delete/add) is real code following
chromadb's documented API, but the full pipeline (embed real text -> store
-> query) has NOT been run successfully end-to-end yet. Run this yourself,
with network access, before trusting it -- if the embedding step itself
fails, that's the first thing to debug.
"""

import os
import chromadb
from sentence_transformers import SentenceTransformer

_COLLECTION_NAME = "exploit_knowledge_base"
_DEFAULT_DB_PATH = os.path.join(os.path.dirname(__file__), "chroma_store")
_KB_DIR = os.path.join(os.path.dirname(__file__), "exploit_knowledge_base")

_embedding_model = None


def _get_embedding_model() -> SentenceTransformer:
    global _embedding_model
    if _embedding_model is None:
        _embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
    return _embedding_model


def build_knowledge_base(kb_dir: str = _KB_DIR, db_path: str = _DEFAULT_DB_PATH) -> int:
    """
    Reads every .txt file in kb_dir (one exploit write-up per file, per the
    format in dao_hack.txt etc.), embeds each, and stores it in a persistent
    local ChromaDB collection.

    Returns the number of documents indexed. Safe to re-run -- recreates the
    collection each time rather than silently appending duplicates on a
    second run.
    """
    if not os.path.isdir(kb_dir):
        raise FileNotFoundError(f"Knowledge base directory not found: {kb_dir}")

    filenames = sorted(f for f in os.listdir(kb_dir) if f.endswith(".txt"))
    if not filenames:
        raise ValueError(f"No .txt exploit write-ups found in {kb_dir}")

    documents, ids, metadatas = [], [], []
    for filename in filenames:
        with open(os.path.join(kb_dir, filename), "r") as f:
            content = f.read()
        documents.append(content)
        ids.append(filename)
        metadatas.append({"filename": filename})

    model = _get_embedding_model()
    embeddings = model.encode(documents, show_progress_bar=False).tolist()

    chroma_client = chromadb.PersistentClient(path=db_path)
    # Recreate the collection on each build so re-running doesn't silently
    # accumulate duplicate entries from a prior run.
    try:
        chroma_client.delete_collection(_COLLECTION_NAME)
    except Exception:
        pass  # collection didn't exist yet -- fine, nothing to delete

    collection = chroma_client.create_collection(_COLLECTION_NAME)
    collection.add(documents=documents, embeddings=embeddings, ids=ids, metadatas=metadatas)

    return len(documents)


if __name__ == "__main__":
    count = build_knowledge_base()
    print(f"Indexed {count} exploit write-ups into {_DEFAULT_DB_PATH}")
