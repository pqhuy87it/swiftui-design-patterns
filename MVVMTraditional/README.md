# MVVMTraditional

A SwiftUI sample app (Unsplash photo browser) built with **plain, traditional MVVM** — no extra layers, no state-machine, no DI framework. Each screen is a `View` backed by an `ObservableObject` **ViewModel** that talks to a **Service**. It is the straightforward counterpart to the sibling `HybridDesignPattern` (Clean + MVVM + UDF) and `TCA(The-Composable-Architecture)` projects — same app, simplest architecture.

The app has three tabs:
- **Home** – latest photos in a Pinterest-style masonry grid with infinite scroll.
- **Topics** – curated topics, each with a horizontal carousel of photos.
- **Search** – search photos by keyword, with persisted search history and infinite scroll.

Image data comes from the [Unsplash API](https://unsplash.com/developers); search history is stored locally with **SwiftData**.

---

## Requirements

- Xcode 16+
- iOS 17+ (uses SwiftData and the modern `TabView` APIs)
- A free Unsplash API access key

---

## Getting Started

### 1. Configure secrets

The Unsplash API key is **not** stored in source code. It is read at runtime from a `Secrets.plist` that is **git-ignored** (see the root `.gitignore` → `**/Secrets.plist`).

1. Get an access key: create a free app at <https://unsplash.com/oauth/applications> and copy the **Access Key**.
2. Copy the template to create your own secrets file:

   ```bash
   cp MVVMTraditional/MVVMTraditional/Config/Secrets.example.plist \
      MVVMTraditional/MVVMTraditional/Config/Secrets.plist
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

Classic **MVVM** with three roles and nothing more:

```
View  ⇄  ViewModel  ⇄  Service
(UI)     (state +      (network / DB)
          intents)
```

| Role | Type | Responsibility |
| --- | --- | --- |
| **View** | SwiftUI `View` | Renders `viewModel.<published>` and calls the ViewModel's async methods on user intent. Owns its ViewModel via `@StateObject`. |
| **ViewModel** | `@MainActor final class … : ObservableObject` | Holds screen state as `@Published private(set)` properties; exposes `async` methods (`loadPhotos()`, `performSearch()`, …); depends only on **service protocols**. |
| **Service** | `struct … : *ServiceProtocol` | Talks to the Unsplash API / SwiftData and returns **domain entities**. |

### 1. The View

Each screen owns its ViewModel with `@StateObject` and reads its published state directly. User intent calls a method (wrapped in a `Task` when async); there is **no** `State`/`Action`/`send` indirection.

```swift
struct PhotosListView: View {
    @StateObject private var viewModel: PhotosViewModel

    init(viewModel: PhotosViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack { content }
            .task { await viewModel.loadPhotos() }   // load on appear
    }
}
```

### 2. The ViewModel

`@MainActor`, `ObservableObject`, state exposed as `@Published private(set)` (the View can read but not mutate it), dependencies injected as **protocols** through `init`.

```swift
@MainActor
final class PhotosViewModel: ObservableObject {
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let photosService: PhotosServiceProtocol

    init(photosService: PhotosServiceProtocol) {
        self.photosService = photosService
    }

    func loadPhotos() async {
        guard photos.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            photos = try await photosService.fetchPhotos(page: 1, perPage: 30)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### 3. The Service

Services conform to a small `*ServiceProtocol` and share the transport helpers from `APIRepositoryProtocol` (`call(endpoint:)`, `baseURL`, `clientId`). Endpoints are described by an `API` enum conforming to `APICall`.

> **No DTO layer.** Unlike the sibling projects, services decode the JSON **directly into the domain entities** (`Photo`, `Topic`, …). The entities are `Codable` and carry the snake_case `CodingKeys` (e.g. `alt_description`, `total_pages`).

```swift
struct PhotosService: APIRepositoryProtocol, PhotosServiceProtocol {
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo] {
        try await call(endpoint: API.latestPhotos(page: page, perPage: perPage, clientId: clientId))
    }
}
```

Services: `PhotosService`, `TopicsService`, `SearchService` (network search **+** SwiftData history), `ImagesService` (downloads raw image data → `UIImage`).

### 4. Parent–child screens & persistence

- **Topics** is a parent/child screen: `TopicsListView` renders a `HeroHeaderView` plus one `TopicHorizontalRow` per topic, and each row builds its own `TopicRowViewModel` that lazily loads that topic's photos.
- **Search history** is persisted with **SwiftData** via `MainDBRepository` (a `@ModelActor`), surfaced through `SearchService` and mapped to `[String]` for the ViewModel.

#### Example: end-to-end flow for the Home screen

```
PhotosListView                         (View)
  └─ .task { await viewModel.loadPhotos() } ─▶ PhotosViewModel        (ViewModel)
                                                 └─ photosService.fetchPhotos(page:perPage:)
                                                      └─ PhotosService  (Service / Unsplash API)
                                                           └─ decode JSON -> [Photo]
                                                 └─ @Published photos = [Photo]
  ◀── re-render masonry grid ──────────────────┘
```

---

## Project Structure

```
MVVMTraditional/
├── App/
│   ├── MVVMTraditionalApp.swift        # @main entry point
│   └── MVVMTraditionalMainView.swift   # root TabView (Home / Topics / Search)
├── Config/
│   ├── AppConfig.swift                 # reads secrets from Secrets.plist
│   ├── Secrets.example.plist           # template (committed)
│   └── Secrets.plist                   # real keys (git-ignored, you create this)
├── Network/                            # ── data layer ──
│   ├── APICall.swift                   # endpoint contract (path, method, headers, body)
│   ├── APIRepositoryProtocol.swift     # transport helper: call(endpoint:), baseURL, clientId
│   ├── Entities/                       # domain models (Photo, Topic, User, SearchResult) + MockedData
│   ├── Interfaces/                     # service protocols (Photos/Topics/Search/Images)
│   ├── Models/                         # APIError, HTTPCode
│   ├── Services/                       # concrete services hitting Unsplash + SwiftData
│   └── Persistence/                    # SwiftData models (DBModel) + MainDBRepository
└── Modules/                            # ── one folder per feature: Views + ViewModels ──
    ├── Common/
    │   ├── ViewModels/                 # ImageViewModel
    │   └── Views/                      # ImageView, ErrorView
    ├── HomePhotos/
    │   ├── ViewModels/                 # PhotosViewModel, PhotoDetailViewModel
    │   └── Views/                      # PhotosListView, PhotoCellView, PhotoDetailView
    ├── Topics/
    │   ├── ViewModels/                 # TopicsViewModel, TopicRowViewModel
    │   └── Views/                      # TopicsListView, TopicHorizontalRow, TopicCardView, HeroHeaderView
    └── Search/
        ├── ViewModels/                 # SearchViewModel
        └── Views/                      # SearchView
```

### Composition root

`MVVMTraditionalMainView` is the small composition root: it creates one shared SwiftData `ModelContainer`, then builds each tab's ViewModel with its concrete service (`PhotosService()`, `TopicsService()`, `SearchService(dbRepository:)`) and hands it to the screen. There is no DI container or factory — dependencies are just constructed and passed in.

---

## Notable features

- **Masonry grid** – `PhotosListView` and `SearchView` lay photos into the shortest column based on each photo's aspect ratio.
- **Infinite scroll** – when the last cell appears, the ViewModel loads the next page and appends it; a guard on `isLoadingMore`/`canLoadMore` prevents duplicate requests.
- **Search history** – persisted with SwiftData via `MainDBRepository`, saved on each explicit search and shown when the search box is empty.
- **Async image loading** – `ImageView(url:)` builds its own `ImageViewModel` and loads the image via `ImagesService`, showing a placeholder until it arrives.
- **Direct JSON → entity decoding** – no DTO layer; the domain entities are `Codable` with snake_case `CodingKeys`.
