# Pokédex — Provider State Management Activity

CS Elective 2 · Ezekiel Daniel Corpuz

## Submission links

**State Management Activity (`state-mgt-act`):**

https://github.com/edmcorpuz/edmcorpuz-Corpuz-CS-Elective-2/tree/state-mgt-act

**Dart Async Activity (`pokedex-act`, grid only):**

https://github.com/edmcorpuz/edmcorpuz-Corpuz-CS-Elective-2/tree/pokedex-act

Submit the appropriate **branch-specific link** in Daigler. The async branch
intentionally stops at the grid; this continuation adds the details page.

## Requirements implemented

- Fetch `https://pokeapi.co/api/v2/pokemon?limit=30&offset=0`.
- Use a dedicated immutable `Pokemon` class: name, image URL, ID.
- Display at most 30 Pokémon in a responsive, scrollable grid.
- Manage initial, loading, success, error, and empty states with Provider.
- Expose the API action as `PokedexProvider.fetchPokemon()`.
- Refresh using the app-bar button or pull-to-refresh on the grid.
- Show retry actions for errors and empty results.
- Open an individual page displaying the selected name, image, and ID.
- Read grid data, request status, error, and selection from shared app state.
- Handle loading/broken artwork, HTTP errors, network errors, malformed data,
  and a 15-second timeout.

## State ownership and data flow

`ChangeNotifierProvider` creates one `PokedexProvider` above `MaterialApp`,
starts its first fetch, and disposes it when the app is removed.

```text
Screen action -> Provider.fetchPokemon() -> PokemonService -> PokéAPI
                         |
                  notifyListeners()
                         |
                  context.watch() -> updated UI
```

The service owns HTTP and JSON parsing. The Provider's API method owns the
loading/error/success transitions and the resulting immutable list. Concurrent
refresh calls share one in-flight Future; disposal safely ignores late results.

Both screens are stateless. They do not hold local Pokémon copies, loading
flags, or error values. Tapping a card records its ID in Provider before
navigation. The details screen reads `selectedPokemon` from Provider, not
constructor/route data. Successful refresh resolves the selection against the
new app-state list; missing selections are cleared. Names and formatted IDs
are computed from model values in app state. Static labels and image-loading
indicators are presentation concerns, not a second source of application data.

## Why Future instead of Stream?

An HTTP request returns one list, so `Future<List<Pokemon>>` is appropriate.
A Stream would fit ongoing events or a live subscription, neither of which
PokéAPI provides here. Each refresh makes a new one-shot request. Provider
notifies the UI of state changes; it does not turn the API into a Stream.
IDs are parsed from Pokémon URLs and used in official-artwork URLs, avoiding
30 extra detail requests.

## Structure

```text
lib/
  main.dart                   Provider scope, application, theme
  models/pokemon.dart         Immutable Pokémon model
  providers/                 App data, request state, selection, API action
  services/                  HTTP, timeout, parsing, readable errors
  screens/                   Grid and Provider-backed details page
  widgets/                   Reusable grid, card, image, status components
test/                        Service, model, Provider, and widget tests
```

## Run locally in VS Code

Developed with Flutter 3.44.8 / Dart 3.12.2. Open the repository folder in
VS Code, use its Flutter extension, select a device, and press **F5**.
The included `.vscode/launch.json` also offers a Chrome configuration.

```sh
flutter pub get
flutter run -d chrome
```

Internet access is required for PokéAPI and artwork. Android internet
permission and macOS outgoing-network entitlements are included.

## Verification

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
```

Tests use mock HTTP responses and cover the 30-result cap, model parsing,
HTTP/network/timeout/malformed-data errors, Provider transitions, refresh
coalescing, selection lifecycle, safe disposal, error/retry/empty UI, both
refresh interactions, scrolling at phone width, and detail navigation.
