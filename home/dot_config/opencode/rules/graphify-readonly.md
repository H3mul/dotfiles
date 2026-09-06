# Rule Layer: Universal Codebase Introspection & Graph-First Exploration

You are structured to prefer deterministic knowledge graphs over raw directory text scans. When asked to locate a mechanic, trace dependencies, chart data flow, or explore an unfamiliar codebase of ANY language or stack, follow this universal hierarchy:

## 🧭 Universal Tool Selection Priority
1. **Detect Index:** Check for an index file (`graphify-out/graph.json` or within the global multi-repo registry `~/.graphify/global-graph.json`).
2. **Prioritize Graph Querying:** If an index is found, you must **actively prioritize running `graphify query`** over executing generic text discovery commands like `grep`, `rg`, or `find`.
3. **Targeted Code Reading:** Only execute `cat` or read file lines *after* the graph has isolated the exact system coordinates or symbols.
4. **Text Fallback:** Revert to native text matching (`grep`/`ripgrep`) only if no graph file exists, or if a non-structural literal string cannot be resolved by code nodes.

## 📋 Language-Agnostic `graphify query` Blueprints
When choosing sub-queries, match the generic structural intent to the corresponding `graphify query` sub-command below:

* **High-Level Topology:** To view the architectural summary, entry points, or primary modules of the project:
  ```bash
  graphify query summary
  ```
* **Symbol Deep Dive:** To isolate a specific class, interface, method, function, or symbol name to see its structural definition:
  ```bash
  graphify query inspect "<symbol_name>"
  ```
* **Impact & Data Flow (Downstream):** To find what downstream modules or files call, consume, or depend on a specific symbol:
  ```bash
  graphify query dependents "<symbol_name>"
  ```
* **Prerequisites & Imports (Upstream):** To discover what upstream files, third-party libraries, packages, or utilities a symbol requires to execute:
  ```bash
  graphify query dependencies "<symbol_name>"
  ```
* **Structural Trace:** To map the shortest architectural connection or call-graph path between two distinct code elements or layers:
  ```bash
  graphify query path --from "<symbol_A>" --to "<symbol_B>"
  ```

## 🚫 Absolute Modification Block
To protect API keys, token ceilings, and system quotas, you operate in a strict read-only sandbox:
* **NEVER execute graph-building commands.** You are strictly forbidden from calling the `/graphify` slash shortcut, `graphify .`, `graphify update`, or any background parsing pipelines.
* If a repository has no graph file, explicitly state: *"Graph index not found. Proceeding with text-based fallback tools to preserve token limits."* and use standard file searchers.
