"""
static_analysis/slither_wrapper.py

ROLE: Deterministic static analysis using Slither (Trail of Bits' Solidity
analyzer). Confirmed working via CLI on tests/vulnerable_contracts/reentrancy_bank.sol
-- Slither correctly detected reentrancy-eth, low-level-calls, and solc-version issues.

This module wraps Slither's CLI (subprocess, --json output) so our pipeline
can call it programmatically and get clean, structured results back, instead
of parsing raw human-readable text.

VERIFIED: `slither --json -` is a real, documented flag (confirmed against
the installed package's own --help output). The JSON parsing logic below was
tested against a synthetic payload matching Slither's actual documented
output schema (results.detectors[], each with check/impact/description/
elements[].source_mapping.lines[]) -- see test_slither_wrapper.py.

NOT VERIFIED end-to-end: actually invoking `slither` against a real .sol
file requires downloading a solc binary from binaries.soliditylang.org,
which is network-blocked in the development sandbox this was built in. The
subprocess call itself and the JSON parsing are real and tested; only the
live compiler invocation is unconfirmed. Run this yourself once, on your own
machine with network access, before trusting it fully.
"""

import subprocess
import json
from dataclasses import dataclass


@dataclass
class Finding:
    vuln_type: str          # e.g. "reentrancy", "access_control"
    severity: str           # "high" / "medium" / "low" / "informational"
    line_number: int | None
    description: str
    source: str = "slither"  # vs "haiku_judge" or "sonnet_reasoning" later


# Slither has 100+ detectors. We only map the ones relevant to our 11
# vulnerability categories -- unmapped detectors fall through to "unknown"
# rather than being silently dropped, so nothing gets lost, just unclassified.
_DETECTOR_TO_CATEGORY = {
    "reentrancy-eth": "reentrancy",
    "reentrancy-no-eth": "reentrancy",
    "reentrancy-benign": "reentrancy",
    "reentrancy-events": "reentrancy",
    "unprotected-upgrade": "access_control",
    "arbitrary-send-eth": "access_control",
    "suicidal": "access_control",
    "tx-origin": "access_control",
    "timestamp": "timestamp_manipulation",
    "weak-prng": "timestamp_manipulation",
    "low-level-calls": "unchecked_call",
    "unchecked-transfer": "unchecked_call",
    "unchecked-lowlevel": "unchecked_call",
    "integer-overflow": "overflow_underflow",
    "divide-before-multiply": "overflow_underflow",
    "calls-loop": "unbounded_loop",
    "costly-loop": "unbounded_loop",
}

# Slither's own "impact" values, normalized to our three-tier severity.
_IMPACT_TO_SEVERITY = {
    "High": "high",
    "Medium": "medium",
    "Low": "low",
    "Informational": "low",
    "Optimization": "low",
}


def _map_detector_to_category(slither_check_name: str) -> str:
    """
    Translate Slither's detector naming (e.g. 'reentrancy-eth') to our
    11-category taxonomy (e.g. 'reentrancy'). Unmapped detectors return
    'unknown' rather than being dropped -- still shown in the report,
    just not bucketed into one of our named categories.
    """
    return _DETECTOR_TO_CATEGORY.get(slither_check_name, "unknown")


def _parse_slither_json(raw_json: dict) -> list[Finding]:
    """
    Parse Slither's documented --json output structure into our Finding
    list. Separated from run_slither() specifically so this parsing logic
    is unit-testable against a synthetic payload without needing a real
    Slither/solc invocation -- see test_slither_wrapper.py.
    """
    findings = []
    detectors = raw_json.get("results", {}).get("detectors", [])

    for detector in detectors:
        check_name = detector.get("check", "")
        category = _map_detector_to_category(check_name)
        severity = _IMPACT_TO_SEVERITY.get(detector.get("impact", ""), "low")
        description = detector.get("description", "").strip()

        line_number = None
        elements = detector.get("elements", [])
        if elements:
            source_mapping = elements[0].get("source_mapping", {})
            lines = source_mapping.get("lines", [])
            if lines:
                line_number = lines[0]

        findings.append(Finding(
            vuln_type=category,
            severity=severity,
            line_number=line_number,
            description=description,
        ))

    return findings


def run_slither(contract_path: str, timeout_s: int = 60) -> list[Finding]:
    """
    Run Slither against a .sol file and return structured findings.

    Uses `slither <path> --json -` to get machine-readable output on
    stdout, rather than parsing human-readable text.

    Handles the two realistic failure modes explicitly rather than letting
    them propagate as opaque exceptions:
    - Compilation failure (missing solc version, syntax error) -> Slither
      exits non-zero with an error on stderr, not valid JSON on stdout.
    - Timeout on a pathologically large/complex contract.

    Both return an empty list with the error captured in a Finding with
    vuln_type="analysis_error", so a failed scan is visible in the report
    rather than silently vanishing.
    """
    try:
        result = subprocess.run(
            ["slither", contract_path, "--json", "-"],
            capture_output=True,
            text=True,
            timeout=timeout_s,
        )
    except subprocess.TimeoutExpired:
        return [Finding(
            vuln_type="analysis_error", severity="high", line_number=None,
            description=f"Slither timed out after {timeout_s}s on {contract_path}.",
            source="slither",
        )]
    except FileNotFoundError:
        return [Finding(
            vuln_type="analysis_error", severity="high", line_number=None,
            description="`slither` command not found -- is slither-analyzer installed?",
            source="slither",
        )]

    if not result.stdout.strip():
        return [Finding(
            vuln_type="analysis_error", severity="high", line_number=None,
            description=f"Slither produced no JSON output. stderr: {result.stderr[:500]}",
            source="slither",
        )]

    try:
        raw_json = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        return [Finding(
            vuln_type="analysis_error", severity="high", line_number=None,
            description=f"Could not parse Slither's JSON output: {e}. stderr: {result.stderr[:500]}",
            source="slither",
        )]

    if not raw_json.get("success", True):
        error_msg = raw_json.get("error", "Unknown Slither error")
        return [Finding(
            vuln_type="analysis_error", severity="high", line_number=None,
            description=f"Slither reported failure: {error_msg}",
            source="slither",
        )]

    return _parse_slither_json(raw_json)
