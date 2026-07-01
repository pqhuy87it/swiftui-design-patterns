# swiftui-design-patterns

A collection of sample iOS apps exploring different ways to architect a SwiftUI codebase. Each top-level folder is a self-contained Xcode project that builds the same kind of feature (an Unsplash photo browser) using a different architectural approach, so they can be compared side by side.

## Projects

| Project | Approach | Docs |
| --- | --- | --- |
| [HybridDesignPattern](HybridDesignPattern/README.md) | Hybrid: **Clean Architecture + MVVM + UDF** | [README](HybridDesignPattern/README.md) |
| [MVVMTraditional](MVVMTraditional/README.md) | Traditional **MVVM** | [README](MVVMTraditional/README.md) |
| [TCA(The-Composable-Architecture)](TCA%28The-Composable-Architecture%29/README.md) | **TCA** (The Composable Architecture) | [README](TCA%28The-Composable-Architecture%29/README.md) |

## HybridDesignPattern

The most documented project. It layers **Clean Architecture** (Domain / Data / Presentation), uses **MVVM** for each screen, and drives every ViewModel with **UDF** (`State` + `Action` + `send`). Features include a masonry photo grid, infinite scroll, topic browsing, and keyword search with locally persisted history.

👉 See the full setup guide (including how to configure the Unsplash API key in `Secrets.plist`) and architecture overview in **[HybridDesignPattern/README.md](HybridDesignPattern/README.md)**.

## MVVMTraditional

The same app in **plain, traditional MVVM** — no extra layers or frameworks. Each screen is a `View` + an `ObservableObject` ViewModel (`@Published` state, `async` methods) talking to a `Service` protocol; services decode JSON straight into the domain entities (no DTO layer). Same feature set: masonry grid, infinite scroll, topics, and keyword search with SwiftData-backed history.

👉 See setup and the MVVM architecture overview in **[MVVMTraditional/README.md](MVVMTraditional/README.md)**.

## TCA (The Composable Architecture)

The same app rebuilt with **[The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)**. Every screen is a `@Reducer` (`State` + `Action` + `body`); a single root `Store` drives the whole app, features compose via `Scope`/`.forEach`, side effects are hidden behind injectable `@DependencyClient` clients, and navigation is state-driven. Includes debounced search and `TestStore` unit tests.

👉 See setup and the TCA architecture overview in **[TCA(The-Composable-Architecture)/README.md](TCA%28The-Composable-Architecture%29/README.md)**.
