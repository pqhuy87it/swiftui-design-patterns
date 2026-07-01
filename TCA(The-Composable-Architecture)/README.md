# TCA (The Composable Architecture)

A SwiftUI sample app (Unsplash photo browser) that demonstrates **[The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)** (TCA): a state-management library built around **reducers**, a single **store**, value-typed **effects**, and **testable dependencies**. It is the TCA counterpart to the sibling `HybridDesignPattern` (Clean + MVVM + UDF) and `MVVMTraditional` projects — same app, different architecture.

The app has three tabs:
- **Home** – latest photos in a Pinterest-style masonry grid with infinite scroll.
- **Topic** – curated topics, each with a horizontal carousel of photos.
- **Search** – search photos by keyword (debounced), with persisted search history.

Image data comes from the [Unsplash API](https://unsplash.com/developers); search history is stored locally with **SwiftData**.

---

## Requirements

- Xcode 16+
- iOS 17+ (uses SwiftData, the modern `TabView`, and the observation-based TCA APIs)
- Swift 6 language mode (the project builds with *default main-actor isolation*)
- A free Unsplash API access key
- [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.26+ (resolved automatically via Swift Package Manager)

---

## Getting Started

### 1. Configure secrets

The Unsplash API key is **not** stored in source code. It is read at runtime from a `Secrets.plist` that is **git-ignored** (see the root `.gitignore` → `**/Secrets.plist`).

1. Get an access key: create a free app at <https://unsplash.com/oauth/applications> and copy the **Access Key**.
2. Copy the template to create your own secrets file:

   ```bash
   cp "TCA(The-Composable-Architecture)/TCA(The-Composable-Architecture)/Config/Secrets.example.plist" \
      "TCA(The-Composable-Architecture)/TCA(The-Composable-Architecture)/Config/Secrets.plist"
   ```

3. Open `Config/Secrets.plist` and replace the placeholder with your real key:

   ```xml
   <dict>
       <key>UnsplashClientID</key>
       <string>YOUR_UNSPLASH_ACCESS_KEY</string>
   </dict>
   ```

4. Build & run. `Secrets.plist` is bundled as a resource and read by `AppConfig`:

   ```swift
   AppConfig.unsplashClientID   // -> value of "UnsplashClientID"
   ```

> ⚠️ Never commit `Secrets.plist`. Only `Secrets.example.plist` (the template) is tracked. If a key value is ever missing or empty, `AppConfig` triggers an `assertionFailure` in debug builds telling you to set it up.

---

## Architecture

TCA organizes the app into **features**. Each feature is a `@Reducer` that owns a `State`, an `Action`, and a `body` describing how actions mutate state and produce side effects. A single **`Store`** drives everything; the UI observes state and sends actions — it never mutates state directly.

| Concern | TCA building block | Where |
| --- | --- | --- |
| Single source of truth for a screen | `@ObservableState struct State` | each `*Feature` |
| Every user/system intent | `enum Action` | each `*Feature` |
| Pure state transitions + side effects | `var body: some Reducer` (`Reduce`) | each `*Feature` |
| Runtime that runs reducers & effects | `Store` / `StoreOf<Feature>` | `App` + views |
| Injectable, testable side effects | `@DependencyClient` clients | `Clients/` |
| Fetching / persistence | Repositories + DTOs + SwiftData | `Data/` |

### 1. Reducers & Store

Every screen is a reducer following the same shape:

```swift
@Reducer
struct PhotosFeature {
    @ObservableState
    struct State: Equatable { /* single source of truth */ }

    enum Action: BindableAction, Equatable { /* every possible intent */ }

    @Dependency(\.photosClient) var photosClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in /* mutate state, return Effect */ }
    }
}
```

Flow: `View → store.send(Action) → Reducer mutates State → View re-renders`. Async work (network/DB) is launched with `.run { send in ... }` effects, and results come back as another `Action` (e.g. `.fetchPhotosResponse(.success/.failure)`).

### 2. Composition (parent ↔ child)

Features compose into a tree. The root **`AppFeature`** owns the three tab features and glues them with `Scope`:

```swift
var body: some Reducer<State, Action> {
    Scope(state: \.photos, action: \.photos) { PhotosFeature() }
    Scope(state: \.topics, action: \.topics) { TopicsFeature() }
    Scope(state: \.search, action: \.search) { SearchFeature() }
}
```

- **Lists of children** – `TopicsFeature` holds an `IdentifiedArrayOf<TopicRowFeature.State>` and embeds each row reducer via `.forEach(\.rows, action: \.row)`.
- **Child → parent communication** – a row can't navigate on its own, so `TopicRowFeature` bubbles a **delegate** action (`.delegate(.photoTapped(photo))`) that the parent `TopicsFeature` intercepts.

### 3. Dependencies (Clients)

Side effects are hidden behind small `@DependencyClient` structs so they can be swapped in previews and tests. Each client wraps the underlying repository and maps **DTO → domain entity**:

```swift
@DependencyClient
struct PhotosClient {
    var fetchPhotos: (_ page: Int, _ perPage: Int) async throws -> [Photo]
}

extension PhotosClient: DependencyKey {
    static let liveValue = PhotosClient(
        fetchPhotos: { page, perPage in
            try await PhotosRepository(session: .shared)
                .fetchPhotos(page: page, perPage: perPage)
                .map { $0.toDomain() }
        }
    )
    static let previewValue = PhotosClient(fetchPhotos: { _, _ in [.mock] })
}
```

Clients: `PhotosClient`, `TopicsClient`, `SearchClient` (also handles history save/fetch), `ImageClient`. Each is exposed through `DependencyValues` and read inside reducers via `@Dependency(\.photosClient)`.

### 4. State-driven navigation

Navigation is data, not imperative calls. Each root feature keeps `var selectedPhoto: Photo?`; tapping a cell sends `.photoTapped(photo)` which sets that value, and the view binds it:

```swift
.navigationDestination(item: $store.selectedPhoto) { photo in
    PhotoDetailView(photo: photo)
}
```

Because navigation lives in `State`, it is fully testable and survives being driven from anywhere (including the child-delegate path in Topics).

### 5. Data layer & error boundary

- **Repositories** hit the Unsplash API and return **DTOs** (`Data/Network/DTOs`, each with `toDomain()`).
- **Clients** call `toDomain()` so reducers only ever see clean domain **entities** (`Photo`, `Topic`, `User`, `SearchResult`).
- Thrown errors are normalized into an **`AppError`** (`Equatable`), so `State`/`Action` stay `Equatable` and are assertable in `TestStore`.
- Search history is persisted with **SwiftData** via `MainDBRepository` (a `@ModelActor`), surfaced through `SearchRepository` → `SearchClient`.

#### Example: end-to-end flow for the Home screen

```
PhotosListView                         (View)
  └─ store.send(.onAppear) ──────────▶ PhotosFeature                (Reducer)
                                         └─ .run { photosClient.fetchPhotos(1, 30) }
                                              └─ PhotosClient         (Dependency)
                                                   └─ PhotosRepository (Data / Unsplash API) -> [PhotoDTO]
                                              └─ dtos.map { $0.toDomain() } -> [Photo]
                                         └─ send(.fetchPhotosResponse(.success([Photo])))
                                         └─ state.photos = [Photo]
  ◀── re-render masonry grid ──────────┘
```

---

## Project Structure

```
TCA(The-Composable-Architecture)/
├── App/                         # @main entry point + root TabView
│   ├── TCA_The_Composable_Architecture_App.swift    # holds the single root Store<AppFeature>
│   └── TCA_The_Composable_Architecture_MainView.swift # TabView + store.scope per tab
├── Features/                    # ── the reducers (State + Action + body) ──
│   ├── AppFeature.swift         # root coordinator (Scope over the 3 tabs)
│   ├── PhotosFeature.swift      # Home: pagination + infinite scroll
│   ├── TopicsFeature.swift      # Topic: hero + list of row features
│   ├── TopicsRowFeature.swift   # one topic carousel (child, delegates taps up)
│   ├── SearchFeature.swift      # Search: debounce + history + results
│   └── ImageFeature.swift       # async image loading for a single URL
├── Clients/                     # ── injectable side effects (@DependencyClient) ──
│   ├── PhotosClient.swift
│   ├── TopicsClient.swift
│   ├── SearchClient.swift
│   └── ImageClient.swift
├── Config/
│   ├── AppConfig.swift          # reads secrets from Secrets.plist
│   ├── Secrets.example.plist    # template (committed)
│   └── Secrets.plist            # real keys (git-ignored, you create this)
├── Entities/                    # domain models (Photo, Topic, User, SearchResult)
├── Data/                        # ── how data is fetched/stored ──
│   ├── Network/
│   │   ├── Interfaces/          # APICall, APIRepositoryProtocol, *RepositoryProtocol
│   │   ├── DTOs/                # Codable response models + toDomain()
│   │   ├── Models/              # APIError, HTTPCode, AppError
│   │   └── Repositories/        # concrete Unsplash repositories
│   ├── Persistence/             # SwiftData models (DBModel) + MainDBRepository
│   └── Mock/                    # MockedData (.mock) for previews/tests
├── Common/                      # reusable views (ImageView host cell, ErrorView)
└── Modules/                     # ── SwiftUI views per feature ──
    ├── HomePhotos/              # PhotosListView, PhotoDetailView
    ├── Topics/                  # TopicsListView, TopicHorizontalRow, cards, hero
    ├── Search/                  # SearchView
    └── Image/                   # ImageView
```

### Composition root

`TCA_The_Composable_Architecture_App` creates **one** `Store(initialState: AppFeature.State()) { AppFeature() }` that lives for the whole app. `MainView` receives it and hands each tab a scoped store via `store.scope(state:action:)`, so every screen operates on its own slice of the shared state tree. Live dependencies (`liveValue`) are used by default; previews and tests override them with `previewValue` / inline stubs through `withDependencies`.

---

## Notable features

- **Masonry grid** – `PhotosListView` lays photos into the shortest column based on each photo's aspect ratio; infinite scroll appends the next page when the last cell appears (guarded by `isLoadingMore`/`canLoadMore`).
- **Debounced search** – typing sends a `.debounce`d effect (0.5s) so the API is hit only after the user pauses; an explicit submit / history tap also persists the keyword. In-flight requests are `.cancellable`.
- **State-driven navigation** – tapping any photo (Home, Search, or a Topic row) opens `PhotoDetailView` by mutating `selectedPhoto` in state.
- **Testable dependencies** – `PhotosFeatureTests` uses `TestStore` to assert exact state changes for both success and failure paths, with `photosClient` overridden — no network required.
- **SwiftData search history** – persisted via the `MainDBRepository` `@ModelActor`, exposed through `SearchClient`.
