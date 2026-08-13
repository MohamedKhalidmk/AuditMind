"""
main.py

Orchestrates the full Mini-AuditAgent pipeline:

    Solidity contract
          |
          v
    router/haiku_router.route_contract()
          |
    +-----+------------------------------+
    |                                    |
STATIC path                        REASONING path
    |                                    |
static_analysis/slither_wrapper    rag/retriever.retrieve_relevant_exploits()
static_analysis/haiku_judge              |
(both run, compared)               router/haiku_router.gate_rag_context()
    |                                    |
    |                              llm_reasoning/sonnet_reasoner.reason_about_contract()
    |                                    |
    +-----------------+------------------+
                       |
                       v
              Combined Finding report
              (printed / saved as JSON)

Run with:
    python main.py tests/vulnerable_contracts/reentrancy_bank.sol

NOT VERIFIED end-to-end: this wires together modules that individually have
mixed verification status (see each module's own docstring) -- slither_wrapper's
JSON parsing is tested, but live slither invocation, all Claude API calls,
and the RAG pipeline are unverified in this build session due to sandbox
network/API-key restrictions. Run this yourself, end to end, on a real
contract with a real API key, before trusting the combined report.
"""

import sys
import json
from dataclasses import asdict

from router.haiku_router import route_contract, gate_rag_context, RouteType
from static_analysis.slither_wrapper import run_slither, Finding
from static_analysis.haiku_judge import judge_contract
from rag.retriever import retrieve_relevant_exploits
from llm_reasoning.sonnet_reasoner import reason_about_contract


def load_contract(path: str) -> str:
    with open(path, "r") as f:
        return f.read()


def run_pipeline(contract_path: str, compare_mode: bool = True) -> dict:
    """
    Full pipeline execution. compare_mode=True runs both Slither and
    Haiku's direct judgment on static-analysis-type findings, so we can
    log agreement/disagreement for the project writeup, regardless of
    which path the router chose.
    """
    contract_source = load_contract(contract_path)

    decision = route_contract(contract_source)

    slither_findings: list[Finding] = []
    haiku_findings: list[Finding] = []
    sonnet_findings: list[Finding] = []

    run_static = decision.route in (RouteType.STATIC, RouteType.BOTH) or compare_mode
    run_reasoning = decision.route in (RouteType.REASONING, RouteType.BOTH)

    if run_static:
        slither_findings = run_slither(contract_path)
        if compare_mode:
            haiku_findings = judge_contract(contract_source)

    if run_reasoning:
        retrieved = retrieve_relevant_exploits(contract_source, top_k=3)
        gated_context = gate_rag_context(contract_source, retrieved)
        sonnet_findings = reason_about_contract(contract_source, gated_context)

    return {
        "contract_path": contract_path,
        "route_decision": {"route": decision.route.value, "reasoning": decision.reasoning},
        "slither_findings": [asdict(f) for f in slither_findings],
        "haiku_findings": [asdict(f) for f in haiku_findings],
        "sonnet_findings": [asdict(f) for f in sonnet_findings],
    }


def print_report(results: dict):
    """Pretty-print findings to console, grouped by source."""
    print("=" * 70)
    print(f"AUDIT REPORT: {results['contract_path']}")
    print("=" * 70)
    print(f"\nRoute decision: {results['route_decision']['route']}")
    print(f"Reasoning: {results['route_decision']['reasoning']}\n")

    sections = [
        ("SLITHER (deterministic static analysis)", results["slither_findings"]),
        ("HAIKU JUDGE (comparison arm — same task as Slither)", results["haiku_findings"]),
        ("SONNET REASONING (intent vs. implementation)", results["sonnet_findings"]),
    ]

    for title, findings in sections:
        print(f"--- {title} ---")
        if not findings:
            print("  (no findings)")
        for f in findings:
            print(f"  [{f['severity'].upper()}] {f['vuln_type']}"
                  + (f" (line {f['line_number']})" if f.get("line_number") else ""))
            print(f"    {f['description']}")
        print()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python main.py <path_to_contract.sol>")
        sys.exit(1)

    results = run_pipeline(sys.argv[1])
    print_report(results)

    with open("audit_report.json", "w") as f:
        json.dump(results, f, indent=2)
    print(f"Full report saved to audit_report.json")
