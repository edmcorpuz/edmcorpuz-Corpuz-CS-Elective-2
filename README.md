# Pokédex — Dart Async Activity

CS Elective 2 · Ezekiel Daniel Corpuz

## Submission

Branch: `pokedex-act`

https://github.com/edmcorpuz/edmcorpuz-Corpuz-CS-Elective-2/tree/pokedex-act

Submit this **branch-specific link** in Daigler.

## Requirements implemented

- Fetch `https://pokeapi.co/api/v2/pokemon?limit=30&offset=0`.
- Display at most 30 Pokémon in a responsive, scrollable grid: name, image, ID.
- Handle loading, API/network errors (with retry), and empty results.
- Handle image loading and broken images independently.
- Stop at the grid: this branch deliberately has **no details page**.
- Separate models, services, widgets, and screens.

## Why Future instead of Stream?

An HTTP GET produces one response: a single list of Pokémon. A
`Future<List<Pokemon>>` represents that one asynchronous result (or error),
whereas a `Stream` is intended for multiple events over time, such as a live
subscription. A `FutureBuilder` renders the pending, failed, and completed
states. The Future is created in `initState`, not `build`, so rebuilds do not
send duplicate API requests. Retry creates a new Future.

IDs are parsed from the API's Pokémon URLs. Official artwork URLs use those
IDs, so the app does not need 30 additional detail requests.

## Structure

```text
lib/
  main.dart                 App and theme
  models/pokemon.dart       Immutable name, image URL, ID model
  services/                 HTTP, timeout, validation, error handling
  screens/                  FutureBuilder-based Pokédex page
  widgets/                  Grid, card, image, status components
 test/                      Model, service, and widget tests
```

## Run locally in VS Code

Use the Flutter/Dart SDK (developed with Flutter 3.44.8 / Dart 3.12.2).
Open this repository folder in VS Code and install its Flutter extension if
needed. Select a device, then press **F5**, or run:

```sh
flutter pub get
flutter run -d chrome
```

Internet access is needed for PokéAPI and artwork. Android internet permission
and macOS outgoing-network entitlements are included.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
```

Tests use an injected mock HTTP client, not the live API. They cover the
30-result cap, parsing, HTTP/network/malformed-data errors, and loading,
empty, error/retry, and grid UI.

The Provider continuation belongs on the separate `state-mgt-act` branch.
