# CleanArchitecture

A SwiftUI sample app (Unsplash photo browser) built with **pure Clean Architecture** in the style of [clean-architecture-swiftui](https://github.com/nalexn/clean-architecture-swiftui): strict Domain / Data / Presentation layering, **no ViewModels**. Each screen is a `View` that holds its state as a `Loadable<T>` and calls **Interactors** (use cases) directly through a `DIContainer` injected via the SwiftUI environment. It is the counterpart to the sibling `MVVMTraditional`, `HybridDesignPattern` (Clean + MVVM + UDF), and `TCA(The-Composable-Architecture)` projects — same app, different architecture.

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
   cp CleanArchitecture/CleanArchitecture/Core/Config/Secrets.example.plist \
      CleanArchitecture/CleanArchitecture/Core/Config/Secrets.plist
   ```

3. Open `Core/Config/Secrets.plist` and replace the placeholder with your real key:

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

The dependency rule points **inward**: `Presentation` and `Data` depend on `Domain`; `Domain` depends on nothing.

```
Presentation ─▶ Domain ◀─ Data
   (Views)      (core)    (API + DB)
```

The distinctive trait of this project (vs. the MVVM siblings) is **there is no ViewModel layer**. The SwiftUI `View` *is* the presentation logic: it owns its state as `Loadable<T>` and drives it by calling Interactors directly.

| Layer | Contents | Depends on |
| --- | --- | --- |
| **Domain** | `Entities`, `Interactors` (use cases), their `Interfaces` (protocols) | nothing |
| **Data** | repository `Interfaces`, `Network` (DTOs + `toDomain()`), concrete `Repositories`, SwiftData `Persistence` | Domain |
| **Presentation** | SwiftUI `Views` + reusable views (`ImageView`, `ErrorView`) | Domain (via `DIContainer`) |

### 1. Domain — the core

- **Entities** – plain domain models (`Photo`, `Topic`, `User`, `SearchResult`).
- **Interactors** – use cases (`PhotosInteractor`, `TopicsInteractor`, `SearchInteractor`, `ImagesInteractor`). They orchestrate repositories and map **DTOs → domain entities**.
- **Interfaces** – the use-case protocols the Presentation layer talks to.

```swift
struct PhotosInteractor: PhotosInteractorProtocol {
    let photosRepository: PhotosRepositoryProtocol
    func fetchPhotos(page: Int, perPage: Int) async throws -> [Photo] {
        try await photosRepository.fetchPhotos(page: page, perPage: perPage).map { $0.toDomain() }
    }
}
```

### 2. Data — how data is fetched/stored

- **Interfaces** – repository protocols + the transport contract (`APIRepositoryProtocol`, `APICall`).
- **Network** – `DTOs` (Codable response models, each with `toDomain()`), `APIError`, `HTTPCode`.
- **Repositories** – concrete repositories that hit the Unsplash API (`PhotosRepository`, `TopicsRepository`, `SearchRepository`, `ImagesRepository`).
- **Persistence** – SwiftData model (`DBModel`) and `MainDBRepository` (a `@ModelActor`) for search history.

### 3. Presentation — Views drive `Loadable` state directly

A screen keeps its state as `@State … Loadable<T>`, reads the `DIContainer` from the environment, and calls the interactor. The `LoadableSubject.load { … }` helper flips the state through `.isLoading → .loaded / .failed`.

```swift
struct PhotosListView: View {
    @Environment(\.injected) private var injected: DIContainer
    @State private var photosState: Loadable<[Photo]> = .notRequested

    var body: some View {
        NavigationStack { content }
    }

    @ViewBuilder private var content: some View {
        switch photosState {
        case .notRequested:  Color.clear.onAppear { loadPhotos() }
        case .isLoading:     ProgressView()
        case let .loaded(photos): grid(photos)
        case let .failed(error):  ErrorView(error: error) { loadPhotos() }
        }
    }

    private func loadPhotos() {
        $photosState.load {
            try await injected.interactors.photos.fetchPhotos(page: 1, perPage: 30)
        }
    }
}
```

- **`Loadable<T>`** – enum `notRequested / isLoading / loaded / failed`; the single source of a screen's async state.
- **`DIContainer`** – holds the `Interactors` (and global `AppState`); injected once at app root via `.inject(container)` and read anywhere with `@Environment(\.injected)`.
- **Parent–child** – `TopicHorizontalRow` is given a `Topic` and loads its own photos into its own `Loadable`, so each carousel is independent.
- **Images** – `ImageView(url:)` holds a `Loadable<UIImage>` and calls `injected.interactors.images.loadImage(url:)` — no image ViewModel.

#### Example: end-to-end flow for the Home screen

```
PhotosListView                       (Presentation / View)
  └─ $photosState.load { … } ──────▶ injected.interactors.photos.fetchPhotos(page:perPage:)
                                        └─ PhotosInteractor       (Domain / use case)
                                             └─ photosRepository.fetchPhotos(...) -> [PhotoDTO]
                                                  └─ PhotosRepository (Data / Unsplash API)
                                             └─ dtos.map { $0.toDomain() } -> [Photo]
                                        └─ photosState = .loaded([Photo])
  ◀── re-render masonry grid ────────┘
```

---

## Project Structure

```
CleanArchitecture/
├── App/
│   ├── CleanArchitectureApp.swift       # @main; bootstraps AppEnvironment, injects DIContainer
│   └── CleanArchitectureMainView.swift  # root TabView (Home / Topics / Search)
├── Core/                                # cross-cutting infrastructure
│   ├── AppState/                        # global app state (Store<AppState>)
│   ├── Config/                          # AppConfig + Secrets(.example).plist
│   ├── DependencyInjection/             # DIContainer + AppEnvironment (composition root)
│   ├── Extensions/                      # Loadable, Store, CancelBag, Helpers
│   └── Mock/                            # MockedData (.mock) for previews
├── Domain/                              # ── inner layer, no framework dependencies ──
│   ├── Entities/                        # Photo, Topic, User, SearchResult
│   ├── Interactors/                     # use cases (map DTO -> entity)
│   └── Interfaces/                      # use-case protocols
├── Data/                                # ── outer layer: how data is fetched/stored ──
│   ├── Interfaces/                      # repository + transport protocols (APICall, APIRepositoryProtocol)
│   ├── Network/                         # DTOs, APIError, HTTPCode
│   ├── Repositories/                    # concrete API repositories
│   └── Persistence/                     # SwiftData model (DBModel) + MainDBRepository
└── Presentation/                        # ── SwiftUI layer (no ViewModels) ──
    ├── Common/                          # ImageView, ErrorView
    └── Modules/
        ├── HomePhotos/Views/            # PhotosListView, PhotoCellView, PhotoDetailView
        ├── Topics/Views/                # TopicsListView, TopicHorizontalRow, TopicCardView, HeroHeaderView
        └── Search/Views/                # SearchView
```

### Composition root

`AppEnvironment.bootstrap()` wires everything together: it builds the `URLSession`, the SwiftData `ModelContainer`, all repositories, all interactors, and packs them into a `DIContainer`. `CleanArchitectureApp` injects that container into the environment (`.inject(_:)`) and the `ModelContainer` via `.modelContainer(_:)`, so every screen resolves its interactors from `@Environment(\.injected)` — no factory, no DI framework.

---

## Notable features

- **Masonry grid** – `PhotosListView` and `SearchView` lay photos into the shortest column based on each photo's aspect ratio.
- **Infinite scroll** – when the last cell appears, the View loads the next page and appends it; a guard on `isLoadingMore`/`canLoadMore` prevents duplicate requests.
- **`Loadable` state machine** – every async screen models `notRequested / isLoading / loaded / failed` explicitly, with a `CancelBag` to cancel in-flight work.
- **Search history** – persisted with SwiftData via `MainDBRepository`, surfaced through `SearchInteractor` and shown when the search box is empty.
- **Async image loading** – `ImageView(url:)` reserves a placeholder and loads the real image through `ImagesInteractor`.
