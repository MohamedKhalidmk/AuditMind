# Mini-AuditAgent

An AI-powered smart contract vulnerability scanner combining deterministic
static analysis (Slither) with LLM reasoning (Claude Haiku + Sonnet) and
RAG-grounded historical exploit explanations.

Inspired by Nethermind's AuditAgent.

## Why this architecture

Static analysis tools (like Slither) are excellent at catching
well-defined, pattern-matchable vulnerabilities — reentrancy, missing
access control, integer overflow — because these have a fixed code
"shape" you can detect deterministically.

But some of the most damaging real-world exploits (Compound's $90M
distribution bug, Synthetix's ~$1B pricing error) were **logic errors**:
the code ran exactly as written, with no unsafe pattern anywhere — the
bug was that the implementation didn't match its intended behavior. No
static analyzer can catch this, because there's nothing structurally
"wrong" with the code. This requires reasoning about **intent vs
implementation**, which is where an LLM becomes genuinely necessary
rather than just convenient.

This project also runs a real empirical comparison: for the
pattern-matchable vulnerability types, does a fast/cheap LLM (Haiku)
actually match Slither's deterministic accuracy? Or is dedicated static
analysis still meaningfully better for those cases? (See `/static_analysis`
— both approaches are implemented so they can be run side by side.)

## Architecture

```
Solidity contract
      |
      v
Haiku Router  --------------------------+
      |                                  |
STATIC path                        REASONING path
      |                                  |
Slither (deterministic)            RAG retrieval (historical exploits)
Haiku direct judgment (comparison)       |
      |                            Haiku gates RAG relevance
      |                                  |
      |                            Sonnet reasons: intent vs implementation
      |                                  |
      +----------------+-----------------+
                       |
                       v
              Combined vulnerability report
```

## Project structure

- `router/` — Haiku-based routing (static vs. reasoning) and RAG relevance gating
- `static_analysis/` — Slither wrapper + Haiku's direct-judgment comparison arm
- `llm_reasoning/` — Sonnet reasoning for logic errors, oracle risk, business-logic mismatches
- `rag/` — Vector store of historical exploits (DAO hack, Parity, Mango Markets, Compound, etc.) used to ground Sonnet's explanations
- `tests/vulnerable_contracts/` — Hand-written test contracts, one per vulnerability category
- `main.py` — Full pipeline orchestration

## Vulnerability categories covered

Reentrancy · Access Control · Integer Overflow/Underflow · Oracle
Manipulation · Flash Loan Attacks · Front-Running · Timestamp Manipulation
· Denial of Service · Signature Replay · Sandwich Vulnerability · Logic
Errors

## Status

Fully implemented — every module has real logic (no stubs), with mixed
verification status per module, stated honestly below rather than claimed
uniformly:

| Module | Status |
|---|---|
| `static_analysis/slither_wrapper.py` | JSON-parsing logic tested against a synthetic payload matching Slither's real documented output schema. Live `slither` CLI invocation is real code (confirmed `slither --json -` is a real, documented flag) but not run end-to-end here — needs a solc compiler binary, which required network access unavailable in this build environment. |
| `router/haiku_router.py` | Real code, follows the same validated prompt/parsing/fallback pattern used elsewhere (temperature=0, code-fence stripping, explicit safe fallback on parse failure). Not run against a live Anthropic API key in this build session. |
| `static_analysis/haiku_judge.py` | Same as above — real code, not run live. |
| `llm_reasoning/sonnet_reasoner.py` | Same as above — real code, not run live. |
| `rag/embed_and_store.py` | Real ChromaDB logic (create/delete/add, following ChromaDB's documented API). The embedding step (sentence-transformers downloading `all-MiniLM-L6-v2`) requires network access to huggingface.co, which failed in this build environment — **not yet run successfully end-to-end**. |
| `rag/retriever.py` | Real query logic, depends on the same unverified embedding step above. |
| `main.py` | Fully wired — every cross-module import has been checked and confirmed to resolve correctly. |

**Before relying on this for a demo or interview:** run the full pipeline
yourself, once, with a real `ANTHROPIC_API_KEY` and normal internet access
(`python -m rag.embed_and_store` first, then `python main.py <contract>`).
Everything here is real, tested logic where testable in a sandboxed
environment — but the pieces needing live network/API access genuinely
have not been executed successfully yet, and that's the honest state to
know before demoing it.

Slither's own detectors were confirmed to correctly identify reentrancy on
`tests/vulnerable_contracts/reentrancy_bank.sol` in earlier manual CLI
testing (`reentrancy-eth`, `low-level-calls`, and `solc-version` all fired
correctly, pinpointing the exact vulnerable lines).

## Setup

```bash
pip install -r requirements.txt
cp .env.example .env  # add your ANTHROPIC_API_KEY

# Build the exploit knowledge base (needs network access for the
# embedding model download, one-time):
python -m rag.embed_and_store

# Run the full pipeline against a test contract:
python main.py tests/vulnerable_contracts/reentrancy_bank.sol
```
