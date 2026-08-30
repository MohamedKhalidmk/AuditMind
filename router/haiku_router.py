"""
router/haiku_router.py

ROLE: Claude Haiku acts as the fast, cheap first-line decision maker.

Two jobs:
1. ROUTE: given a contract, decide whether it's a STATIC pattern-matchable
   case (reentrancy, access control, overflow, timestamp misuse, unbounded
   loops) or a REASONING case that needs deeper LLM analysis (logic errors,
   oracle risk, business-logic mismatches).

2. GATE (RAG quality control): when the reasoning path retrieves historical
   exploit context from the RAG store, Haiku decides whether that retrieved
   context is actually relevant enough to pass to Sonnet, or whether it
   should be dropped so Sonnet reasons without noisy/irrelevant context.
   (Same pattern used in MediLink's gateway / smartune's decision_engine --
   Claude reasons over already-retrieved candidates, it doesn't fetch or
   score them blind.)

NOT VERIFIED: both functions below make real Anthropic API calls and have
not been run against a live key in this build session (no API key available
in the sandbox this was written in). The prompt structure, JSON parsing, and
fallback behavior follow the same validated pattern as smartune's
curation/curator.py and decision_engine.py (temperature=0, code-fence
stripping, explicit fallback on parse failure) -- run this once with a real
key before trusting it fully.
"""

import json
import os
from dataclasses import dataclass
from enum import Enum

import anthropic

client = anthropic.Anthropic()


class RouteType(Enum):
    STATIC = "static_analysis"       # pattern-matchable, send to Slither/haiku_judge
    REASONING = "llm_reasoning"      # needs Sonnet (+ optional RAG)
    BOTH = "both"                    # contract has both kinds of risk surface


@dataclass
class RouteDecision:
    route: RouteType
    reasoning: str  # Haiku's brief justification for the routing decision


ROUTE_PROMPT = """You are the first-line router in a smart contract security pipeline.

Given this Solidity contract, decide whether its risk surface is dominated by:
- STATIC: well-defined, pattern-matchable vulnerabilities that deterministic static analysis tools reliably catch (reentrancy, missing access control, integer overflow, unbounded loops, timestamp misuse, unchecked external calls)
- REASONING: vulnerabilities that require understanding INTENT vs IMPLEMENTATION -- logic errors, oracle manipulation risk, business-logic mismatches, flash loan attack surfaces -- where the code has no unsafe *pattern*, but doesn't do what it's supposed to
- BOTH: the contract has meaningful risk surface of both kinds

Contract:
```solidity
{contract_source}
```

Respond ONLY with JSON: {{"route": "STATIC" | "REASONING" | "BOTH", "reasoning": "<1-2 sentences>"}}"""

GATE_PROMPT = """A smart contract security reasoner is about to receive historical exploit precedents as context. Filter out any that are NOT actually relevant to this specific contract/query, so irrelevant precedent doesn't pollute the reasoning.

Query / contract context: {query}

Candidate historical exploits retrieved:
{numbered_chunks}

Respond ONLY with JSON: {{"relevant_indices": [<list of integers, 0-indexed, of the chunks that are actually relevant>], "reasoning": "<1 sentence>"}}"""


def _strip_code_fence(text: str) -> str:
    text = text.strip()
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.strip()
    return text


def route_contract(contract_source: str) -> RouteDecision:
    """
    Ask Haiku whether this contract needs static analysis, deep reasoning,
    or both. Falls back to BOTH on any parse failure -- the safe default
    when we can't get a confident routing decision is to run everything,
    not to skip a path silently.
    """
    prompt = ROUTE_PROMPT.format(contract_source=contract_source)

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=300,
        temperature=0,
        messages=[{"role": "user", "content": prompt}],
    )
    text = _strip_code_fence(response.content[0].text)

    try:
        result = json.loads(text)
        route = RouteType[result["route"]]
        return RouteDecision(route=route, reasoning=result.get("reasoning", ""))
    except (json.JSONDecodeError, KeyError, ValueError) as e:
        return RouteDecision(
            route=RouteType.BOTH,
            reasoning=f"Routing decision failed to parse ({e}) -- defaulting to BOTH paths for safety.",
        )


def gate_rag_context(query: str, retrieved_chunks: list[str]) -> list[str]:
    """
    Filter retrieved RAG chunks (historical exploits) down to only the ones
    actually relevant to this specific contract/query. On parse failure,
    falls back to returning ALL chunks unfiltered -- safer to let Sonnet see
    a possibly-irrelevant chunk than to silently drop context it might have
    needed.
    """
    if not retrieved_chunks:
        return []

    numbered = "\n\n".join(f"[{i}] {chunk}" for i, chunk in enumerate(retrieved_chunks))
    prompt = GATE_PROMPT.format(query=query, numbered_chunks=numbered)

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=300,
        temperature=0,
        messages=[{"role": "user", "content": prompt}],
    )
    text = _strip_code_fence(response.content[0].text)

    try:
        result = json.loads(text)
        indices = result["relevant_indices"]
        return [retrieved_chunks[i] for i in indices if 0 <= i < len(retrieved_chunks)]
    except (json.JSONDecodeError, KeyError, TypeError, IndexError):
        return retrieved_chunks
