"""
static_analysis/haiku_judge.py

ROLE: Experimental comparison arm. For the SAME static-pattern-type
vulnerabilities that Slither checks deterministically, we also ask Haiku
to judge the contract directly -- so we can compare a fast/cheap LLM's
accuracy against dedicated static analysis on cases that HAVE a fixed,
learnable pattern. See README's "Why this architecture" for the actual
question this answers: is a static analyzer still meaningfully better than
an LLM for pattern-matchable bugs, or does Haiku match it?

This is deliberately kept separate from llm_reasoning/sonnet_reasoner.py --
that module handles cases with NO fixed pattern (logic errors, intent
mismatches). This one is Haiku attempting the SAME job Slither does, for
comparison, not a different job.

NOT VERIFIED: makes a real Anthropic API call, not run against a live key
in this build session.
"""

import json

import anthropic

from static_analysis.slither_wrapper import Finding

client = anthropic.Anthropic()

JUDGE_PROMPT = """You are checking a Solidity contract for well-defined, pattern-matchable vulnerabilities ONLY -- the kind a static analyzer looks for. Do NOT reason about business logic intent or subtle economic exploits; only report vulnerabilities with a fixed, recognizable code pattern.

Check specifically for:
- Reentrancy (external call before state update)
- Missing access control on sensitive functions
- Integer overflow/underflow
- Unbounded loops (potential DoS)
- Timestamp manipulation risk (block.timestamp used unsafely)
- Unchecked low-level calls

Contract:
```solidity
{contract_source}
```

Respond ONLY with JSON: {{"findings": [{{"vuln_type": "<one of: reentrancy, access_control, overflow_underflow, unbounded_loop, timestamp_manipulation, unchecked_call>", "severity": "<high|medium|low>", "line_number": <int or null>, "description": "<one sentence>"}}]}}
If no issues found, respond with {{"findings": []}}."""


def judge_contract(contract_source: str) -> list[Finding]:
    """
    Ask Haiku to directly judge the contract for the same pattern-matchable
    vulnerability categories Slither checks. Returns Finding objects tagged
    source="haiku_judge" so main.py can display them alongside Slither's
    findings for direct agreement/disagreement comparison.

    On parse failure, returns a single Finding with vuln_type="analysis_error"
    rather than silently returning an empty list -- an empty list would look
    identical to "Haiku found nothing," which is a materially different,
    misleading claim compared to "Haiku's response couldn't be parsed."
    """
    prompt = JUDGE_PROMPT.format(contract_source=contract_source)

    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=800,
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
                severity=f.get("severity", "low"),
                line_number=f.get("line_number"),
                description=f.get("description", ""),
                source="haiku_judge",
            ))
        return findings
    except (json.JSONDecodeError, KeyError) as e:
        return [Finding(
            vuln_type="analysis_error", severity="high", line_number=None,
            description=f"Haiku judge response could not be parsed: {e}",
            source="haiku_judge",
        )]
