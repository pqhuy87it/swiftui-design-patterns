# swiftui-design-patterns

A collection of sample iOS apps exploring different ways to architect a SwiftUI codebase. Each top-level folder is a self-contained Xcode project that builds the same kind of feature (an Unsplash photo browser) using a different architectural approach, so they can be compared side by side.

## Projects

| Project | Approach | Docs |
| --- | --- | --- |
| [HybridDesignPattern](HybridDesignPattern/README.md) | Hybrid: **Clean Architecture + MVVM + UDF** | [README](HybridDesignPattern/README.md) |
| `MVVMTraditional` | Traditional **MVVM** | — |
| `TCA(The-Composable-Architecture)` | **TCA** (The Composable Architecture) | — |

## HybridDesignPattern

The most documented project. It layers **Clean Architecture** (Domain / Data / Presentation), uses **MVVM** for each screen, and drives every ViewModel with **UDF** (`State` + `Action` + `send`). Features include a masonry photo grid, infinite scroll, topic browsing, and keyword search with locally persisted history.

👉 See the full setup guide (including how to configure the Unsplash API key in `Secrets.plist`) and architecture overview in **[HybridDesignPattern/README.md](HybridDesignPattern/README.md)**.
