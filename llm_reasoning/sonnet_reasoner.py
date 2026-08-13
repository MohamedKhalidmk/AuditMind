"""
llm_reasoning/sonnet_reasoner.py

ROLE: Deep reasoning layer using Claude Sonnet for vulnerabilities that have
NO fixed pattern -- the ones static analysis and even Haiku's quick judgment
(static_analysis/haiku_judge.py) can't catch, because there's nothing
structurally "wrong" with the code. This requires reasoning about INTENT vs
IMPLEMENTATION: does what the code actually does match what it's supposed
to do, given the contract's evident purpose?

Grounded in historical precedent: gated_context (from
router.gate_rag_context, already filtered for relevance) is included in the
prompt so Sonnet's explanation cites a real, analogous exploit rather than a
generic description -- same grounding principle as MediLink's RAG pipeline
and smartune's curation rubric (specific, checkable reasoning over vague
confidence).

NOT VERIFIED: makes a real Anthropic API call, not run against a live key
in this build session.
"""

import json

import anthropic

from static_analysis.slither_wrapper import Finding

client = anthropic.Anthropic()

REASONING_PROMPT = """You are a smart contract security auditor reasoning about INTENT vs IMPLEMENTATION -- not pattern-matching, but asking: does this code actually do what it's supposed to do, given its evident purpose? Look specifically for:
- Logic errors (the code runs as written but the logic doesn't match intended behavior)
- Oracle manipulation risk (price/data feeds that could be manipulated or are trusted without validation)
- Business-logic mismatches (functions that don't enforce the invariants their names/comments imply)
- Flash loan attack surfaces (state that could be manipulated within a single transaction)

Contract:
```solidity
{contract_source}
```
{context_section}
For each issue found, if one of the historical exploits above is genuinely analogous, cite it by name and explain the parallel. If none are analogous, don't force a citation.

Respond ONLY with JSON: {{"findings": [{{"vuln_type": "<short descriptive name, e.g. 'oracle_manipulation' or 'logic_error'>", "severity": "<high|medium|low>", "line_number": <int or null>, "description": "<explanation including intent-vs-implementation reasoning, and a cited precedent if genuinely analogous>"}}]}}
If no issues found, respond with {{"findings": []}}."""


def reason_about_contract(contract_source: str, gated_context: list[str] | None = None) -> list[Finding]:
    """
    Ask Sonnet to reason about intent-vs-implementation vulnerabilities,
    optionally grounded in gated_context (already-filtered historical
    exploit write-ups from rag/retriever.py + router/haiku_router.py's
    relevance gate).

    gated_context should already be filtered for relevance before reaching
    here -- this function trusts what it's given rather than re-filtering,
    keeping the relevance decision in one place (the router).
    """
    if gated_context:
        context_section = (
            "\nRelevant historical exploits for context:\n\n"
            + "\n\n---\n\n".join(gated_context)
            + "\n"
        )
    else:
        context_section = "\n"

    prompt = REASONING_PROMPT.format(contract_source=contract_source, context_section=context_section)

    response = client.messages.create(
        model="claude-sonnet-4-5",
        max_tokens=1200,
        temperature=0,
        messages=[{"role": "user", "content": prompt}],
    )
    text = response.content[0].text.strip()
    if text.startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.strip()

    try:
        result = json.loads(text)
        findings = []
        for f in result.get("findings", []):
            findings.append(Finding(
                vuln_type=f["vuln_type"],
                severity=f.get("severity", "medium"),
                line_number=f.get("line_number"),
                description=f.get("description", ""),
                source="sonnet_reasoning",
            ))
        return findings
    except (json.JSONDecodeError, KeyError) as e:
        return [Finding(
            vuln_type="analysis_error", severity="high", line_number=None,
            description=f"Sonnet reasoning response could not be parsed: {e}",
            source="sonnet_reasoning",
        )]
