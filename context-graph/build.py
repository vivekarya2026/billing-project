"""
build.py
--------
Entry point for the context-graph agent.

Usage:
    python context-graph/build.py

Reads both source docs in 'Intial Document/', extracts entities and
relationships, then writes:
  - context-graph/vault/  (Obsidian notes with [[wikilinks]])
  - context-graph/OVERVIEW.md  (Mermaid map + entity counts)
  - context-graph/graph.json  (serialised graph for inspection)

This script is idempotent. Run it whenever the source docs change.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from dataclasses import asdict

# Make sure the parent directory is on the path when running as a script
sys.path.insert(0, str(Path(__file__).parent.parent))

from graph_agent.parse import parse_all
from graph_agent.extract import build_graph
from graph_agent.emit_obsidian import emit as emit_obsidian
from graph_agent.emit_mermaid import emit as emit_mermaid


def _serialise_graph(graph) -> dict:
    """Turn the graph into a JSON-friendly dict."""
    return {
        "nodes": [
            {
                "id": n.id,
                "entity_type": n.entity_type,
                "label": n.label,
                "attributes": {
                    k: v for k, v in n.attributes.items()
                    if not isinstance(v, dict) or not any(
                        isinstance(vv, list) and len(vv) > 20
                        for vv in v.values()
                    )
                },
            }
            for n in graph.nodes
        ],
        "edges": [
            {
                "source": e.source,
                "target": e.target,
                "relation": e.relation,
                "confidence": e.confidence,
                "note": e.note,
            }
            for e in graph.edges
        ],
    }


def main() -> None:
    base = Path(__file__).parent

    print("Building context graph...")
    print()

    # Step 1: Parse source documents
    print("Step 1/4: Parsing source documents...")
    docs = parse_all()
    print(f"  ✓ {len(docs.decisions)} decisions, {len(docs.personas)} personas, "
          f"{len(docs.features)} features, {len(docs.user_stories)} user stories, "
          f"{len(docs.flows)} flows, {len(docs.security_items)} security items, "
          f"{len(docs.pipeline_stages)} pipeline stages")

    # Step 2: Extract graph
    print("Step 2/4: Extracting entities and relationships...")
    graph = build_graph(docs)
    print(f"  ✓ {len(graph.nodes)} nodes, {len(graph.edges)} edges")

    # Step 3: Emit Obsidian vault
    print("Step 3/4: Writing Obsidian vault notes...")
    emit_obsidian(graph)

    # Step 4: Emit Mermaid overview
    print("Step 4/4: Writing OVERVIEW.md...")
    emit_mermaid(graph)

    # Bonus: save graph.json
    graph_json_path = base / "graph.json"
    graph_json_path.write_text(
        json.dumps(_serialise_graph(graph), indent=2, ensure_ascii=False),
        encoding="utf-8"
    )
    print(f"  ✓ Wrote {graph_json_path}")

    print()
    print("Done.")
    print()
    print("To explore the graph:")
    print("  1. Open Obsidian")
    print("  2. Open vault: context-graph/vault/")
    print("  3. Press Cmd+G (or Ctrl+G) to open Graph View")
    print()
    print("To regenerate after editing source docs:")
    print("  python context-graph/build.py")


if __name__ == "__main__":
    main()
